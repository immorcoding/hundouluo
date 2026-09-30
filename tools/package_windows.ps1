[CmdletBinding()]
param(
	[string]$GodotPath,
	[string]$OutputDirectory,
	[ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]*$')]
	[string]$PackageLabel = 'preparation',
	[switch]$CheckOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-GodotExecutable {
	param([string]$RequestedPath)

	if (-not [string]::IsNullOrWhiteSpace($RequestedPath)) {
		if (Test-Path -LiteralPath $RequestedPath -PathType Leaf) {
			return (Resolve-Path -LiteralPath $RequestedPath).Path
		}
		$requestedCommand = Get-Command -Name $RequestedPath -ErrorAction SilentlyContinue
		if ($null -ne $requestedCommand) {
			return $requestedCommand.Source
		}
		throw "Godot executable was not found: $RequestedPath"
	}

	foreach ($candidate in @('Godot_v4.7.2-stable_win64_console.exe', 'godot')) {
		$command = Get-Command -Name $candidate -ErrorAction SilentlyContinue
		if ($null -ne $command) {
			return $command.Source
		}
	}
	throw 'Godot 4.7.2 console executable was not found. Pass -GodotPath explicitly.'
}

function Invoke-GodotChecked {
	param(
		[Parameter(Mandatory = $true)][string]$Executable,
		[Parameter(Mandatory = $true)][string[]]$GodotArguments,
		[Parameter(Mandatory = $true)][string]$Operation
	)

	# PowerShell does not reliably wait for a GUI-subsystem EXE or refresh
	# LASTEXITCODE. Own the process so exported-game checks use its real result.
	$startInfo = [Diagnostics.ProcessStartInfo]::new()
	$startInfo.FileName = $Executable
	$startInfo.UseShellExecute = $false
	$startInfo.CreateNoWindow = $true
	$startInfo.RedirectStandardOutput = $true
	$startInfo.RedirectStandardError = $true
	if ($null -ne $startInfo.PSObject.Properties['ArgumentList']) {
		foreach ($argument in $GodotArguments) { $startInfo.ArgumentList.Add($argument) }
	} else {
		# .NET Framework/Windows PowerShell: quote argv without invoking a shell.
		$quotedArguments = foreach ($argument in $GodotArguments) {
			$escaped = [regex]::Replace($argument, '(\\*)"', '$1$1\"')
			'"' + [regex]::Replace($escaped, '(\\+)$', '$1$1') + '"'
		}
		$startInfo.Arguments = $quotedArguments -join ' '
	}
	$process = [Diagnostics.Process]::new()
	$process.StartInfo = $startInfo
	try {
		if (-not $process.Start()) { throw "Could not start $Operation." }
		$stdout = $process.StandardOutput.ReadToEndAsync()
		$stderr = $process.StandardError.ReadToEndAsync()
		$process.WaitForExit()
		$operationExitCode = $process.ExitCode
		$operationOutput = @($stdout.GetAwaiter().GetResult(), $stderr.GetAwaiter().GetResult())
	} finally {
		$process.Dispose()
	}
	$operationOutput | Write-Output
	if ($operationExitCode -ne 0) {
		throw "$Operation failed with exit code $operationExitCode."
	}
	if ($operationOutput | Select-String -Pattern '(?m)^\s*(ERROR:|SCRIPT ERROR:|WARNING:)') {
		throw "$Operation emitted diagnostics despite exit code 0; inspect the output above."
	}
}

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$projectFile = Join-Path $projectRoot 'project.godot'
$presetFile = Join-Path $projectRoot 'export_presets.cfg'
$releaseTemplate = Join-Path (Join-Path $env:APPDATA 'Godot\export_templates\4.7.2.stable') 'windows_release_x86_64.exe'

foreach ($requiredPath in @($projectFile, $presetFile, (Join-Path $projectRoot 'docs\release-prep.md'))) {
	if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
		throw "Required project file is missing: $requiredPath"
	}
}

$resolvedGodotPath = Resolve-GodotExecutable -RequestedPath $GodotPath
$versionOutput = @(& $resolvedGodotPath --version 2>&1)
$versionExitCode = $LASTEXITCODE
$godotVersion = ($versionOutput -join "`n").Trim()
if ($versionExitCode -ne 0 -or $godotVersion -notmatch '^4\.7\.2\.stable\.official\.') {
	throw "Godot 4.7.2 stable is required; found '$godotVersion'."
}
if (-not (Test-Path -LiteralPath $releaseTemplate -PathType Leaf)) {
	throw "The Godot 4.7.2 Windows x86_64 release template is missing: $releaseTemplate"
}

if ($CheckOnly) {
	Write-Output "Windows packaging preflight passed: Godot $godotVersion; Windows x86_64 release template is installed."
	return
}

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
	throw 'Pass -OutputDirectory outside the project checkout; generated packages are intentionally kept out of source control.'
}

$outputCandidate = if ([IO.Path]::IsPathRooted($OutputDirectory)) {
	$OutputDirectory
} else {
	Join-Path $projectRoot $OutputDirectory
}
$outputPath = [IO.Path]::GetFullPath($outputCandidate)
$normalizedProjectRoot = [IO.Path]::GetFullPath($projectRoot).TrimEnd('\', '/')
$projectRootPrefix = $normalizedProjectRoot + [IO.Path]::DirectorySeparatorChar
if ($outputPath.Equals($normalizedProjectRoot, [StringComparison]::OrdinalIgnoreCase) -or $outputPath.StartsWith($projectRootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
	throw 'OutputDirectory must be outside the project checkout.'
}

$gitCommand = Get-Command -Name 'git.exe' -ErrorAction SilentlyContinue
if ($null -eq $gitCommand) {
	$gitCommand = Get-Command -Name 'git' -ErrorAction SilentlyContinue
}
if ($null -eq $gitCommand) {
	throw 'Git is required to create matching source and Windows packages from one committed revision.'
}

$worktreeStatus = @(& $gitCommand.Source -C $projectRoot status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0) {
	throw 'Could not inspect the project worktree with Git.'
}
if ($worktreeStatus.Count -gt 0) {
	throw 'Commit or remove all non-ignored worktree changes before packaging. The source and executable must match one clean commit.'
}

$sourceCommit = (& $gitCommand.Source -C $projectRoot rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $sourceCommit -notmatch '^[0-9a-f]{40}$') {
	throw 'Could not resolve the committed source revision.'
}
$shortCommit = $sourceCommit.Substring(0, 12)
$sourceArchiveName = "hundouluo-$PackageLabel-source-$shortCommit.zip"
$windowsArchiveName = "hundouluo-$PackageLabel-windows-x86_64-$shortCommit.zip"
$sourcePackagePath = Join-Path $outputPath $sourceArchiveName
$windowsPackagePath = Join-Path $outputPath $windowsArchiveName
foreach ($packagePath in @($sourcePackagePath, $windowsPackagePath)) {
	if (Test-Path -LiteralPath $packagePath) {
		throw "Refusing to overwrite an existing package: $packagePath"
	}
}

$temporaryRoot = Join-Path $env:TEMP ('hundouluo-windows-' + [guid]::NewGuid().ToString('N'))
$sourceArchivePath = Join-Path $temporaryRoot 'source.zip'
$projectCopy = Join-Path $temporaryRoot 'project'
$exportDirectory = Join-Path $temporaryRoot 'export'
$packageDirectory = Join-Path $temporaryRoot 'windows-package'
$extractedPackage = Join-Path $temporaryRoot 'fresh-extraction'
$createdOutputFiles = [Collections.Generic.List[string]]::new()
$packageSucceeded = $false

try {
	New-Item -ItemType Directory -Path $temporaryRoot, $projectCopy, $exportDirectory, $packageDirectory | Out-Null
	& $gitCommand.Source -C $projectRoot archive --format=zip --output=$sourceArchivePath HEAD
	if ($LASTEXITCODE -ne 0) {
		throw 'Git could not create the source snapshot.'
	}
	Expand-Archive -LiteralPath $sourceArchivePath -DestinationPath $projectCopy

	Invoke-GodotChecked -Executable $resolvedGodotPath -GodotArguments @('--headless', '--editor', '--path', $projectCopy, '--import') -Operation 'Godot resource import'
	Invoke-GodotChecked -Executable $resolvedGodotPath -GodotArguments @('--headless', '--path', $projectCopy, '--script', 'tests/windows_export_preset_smoke.gd') -Operation 'Windows export preset smoke test'
	Invoke-GodotChecked -Executable $resolvedGodotPath -GodotArguments @('--headless', '--path', $projectCopy, '--quit-after', '2') -Operation 'Main-scene startup check'

	$nameSetting = Select-String -LiteralPath (Join-Path $projectCopy 'project.godot') -Pattern '^config/name=' | Select-Object -First 1
	if ($null -eq $nameSetting) {
		throw 'Could not read config/name from project.godot.'
	}
	$projectName = ($nameSetting.Line -split '=', 2)[1].Trim().Trim('"')
	if ([string]::IsNullOrWhiteSpace($projectName) -or $projectName.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
		throw "Project name cannot be used as a Windows filename: $projectName"
	}

	$executablePath = Join-Path $exportDirectory ($projectName + '.exe')
	Invoke-GodotChecked -Executable $resolvedGodotPath -GodotArguments @('--headless', '--path', $projectCopy, '--export-release', 'Windows Desktop', $executablePath) -Operation 'Windows Release export'
	if (-not (Test-Path -LiteralPath $executablePath -PathType Leaf)) {
		throw 'Godot reported a successful export but did not create the Windows executable.'
	}
	if ((Get-Item -LiteralPath $executablePath).Length -lt 1048576) {
		throw 'The exported Windows executable is unexpectedly small.'
	}
	$externalPacks = @(Get-ChildItem -LiteralPath $exportDirectory -Filter '*.pck' -File)
	if ($externalPacks.Count -gt 0) {
		throw 'The self-contained export preset unexpectedly produced an external PCK file.'
	}

	Copy-Item -LiteralPath $executablePath -Destination $packageDirectory
	Copy-Item -LiteralPath (Join-Path $projectCopy 'README.md') -Destination $packageDirectory
	Copy-Item -LiteralPath (Join-Path $projectCopy 'LICENSE') -Destination $packageDirectory
	$packageDocs = Join-Path $packageDirectory 'docs'
	New-Item -ItemType Directory -Path $packageDocs | Out-Null
	Copy-Item -LiteralPath (Join-Path $projectCopy 'docs\assets-manifest.md') -Destination $packageDocs
	Copy-Item -LiteralPath (Join-Path $projectCopy 'docs\release-prep.md') -Destination $packageDocs
	Copy-Item -LiteralPath (Join-Path $projectCopy 'docs\retest-v0.1.1-rc.3.md') -Destination $packageDocs
	Copy-Item -LiteralPath (Join-Path $projectCopy 'docs\known-issues-v0.1.1.md') -Destination $packageDocs
	Invoke-GodotChecked -Executable $resolvedGodotPath -GodotArguments @('--headless', '--path', $projectCopy, '--script', 'tools/export_engine_notices.gd', '--', $packageDirectory) -Operation 'Engine distribution notices'
	$playInstructions = @(
		"轨道基地 $PackageLabel · Windows 候选试玩说明"
		''
		'将 ZIP 完整解压到一个文件夹；双击“轨道基地.exe”即可运行，无需安装 Godot。'
		'系统：Windows x86_64。若未启动，请记录 Windows 版本与错误提示。'
		'按键：A / ← 向左，D / → 向右，空格跳跃，按住 J 连续射击。'
		'死亡或任务完成画面按 R，从关卡起点重新开始。'
		'rc.1 的美术、声音、手感及其余项已通过；真人机甲时间沿用用户“时间差不多”。'
		'本轮主项 #36：枪口火光可见起始端贴合枪口，左右连射/变向/跳跃/受击时枪身不闪烁。'
		'#34 残骸遮人和 #35 跑射枪口尚未确认，保留原项；顺路确认通关/R，不要求重验旧整张单。'
		'请复制 docs/retest-v0.1.1-rc.3.md 的定点复测单填写，结果提交到：'
		'https://github.com/immorcoding/hundouluo/issues/31'
		'这是复测候选；三项修复待用户确认，尚未正式封版。'
		'已知事项见 docs/known-issues-v0.1.1.md；Godot 引擎与第三方完整通知见包根 GODOT_* 文件。'
		'包版本和源码提交见 BUILD_INFO.txt；素材来源见 docs/assets-manifest.md。'
	) -join "`r`n"
	[IO.File]::WriteAllText((Join-Path $packageDirectory '试玩说明.txt'), $playInstructions + "`r`n", [Text.UTF8Encoding]::new($false))

	$buildInfo = @(
		'package_label=' + $PackageLabel
		'source_commit=' + $sourceCommit
		'godot_version=' + $godotVersion
		'export_preset=Windows Desktop'
		'architecture=x86_64'
		'project_data=embedded_in_executable'
		'prior_human_acceptance=https://github.com/immorcoding/hundouluo/issues/31#issuecomment-5911543601'
		'prior_human_results=other_items_passed;mech_time_report=时间差不多'
		'current_human_feedback=https://github.com/immorcoding/hundouluo/issues/36'
		'本候选人工复测：#36主项；#34/#35保留；均未确认'
		'技术构建：Godot 导入、导出与解压启动已验证；只待三bug定点复测和必要通关/R防退化'
	) -join "`r`n"
	[IO.File]::WriteAllText((Join-Path $packageDirectory 'BUILD_INFO.txt'), $buildInfo + "`r`n", [Text.UTF8Encoding]::new($false))

	if (-not (Test-Path -LiteralPath $outputPath -PathType Container)) {
		New-Item -ItemType Directory -Path $outputPath | Out-Null
	}
	Copy-Item -LiteralPath $sourceArchivePath -Destination $sourcePackagePath
	$createdOutputFiles.Add($sourcePackagePath)
	Compress-Archive -Path (Join-Path $packageDirectory '*') -DestinationPath $windowsPackagePath -CompressionLevel Optimal
	$createdOutputFiles.Add($windowsPackagePath)

	Expand-Archive -LiteralPath $windowsPackagePath -DestinationPath $extractedPackage
	$extractedExecutable = Join-Path $extractedPackage ($projectName + '.exe')
	if (-not (Test-Path -LiteralPath $extractedExecutable -PathType Leaf)) {
		throw 'Freshly extracted package does not contain the game executable.'
	}
	Invoke-GodotChecked -Executable $extractedExecutable -GodotArguments @('--headless', '--quit-after', '2') -Operation 'Freshly extracted executable startup check'

	$packageSucceeded = $true
	Write-Output "Source package: $sourcePackagePath"
	Write-Output "Windows package: $windowsPackagePath"
	Write-Output "Unpacked startup passed for source commit $sourceCommit."
} finally {
	if (-not $packageSucceeded) {
		foreach ($createdOutputFile in $createdOutputFiles) {
			if (Test-Path -LiteralPath $createdOutputFile -PathType Leaf) {
				Remove-Item -LiteralPath $createdOutputFile -Force
			}
		}
	}
	if (Test-Path -LiteralPath $temporaryRoot -PathType Container) {
		$resolvedTemporaryRoot = [IO.Path]::GetFullPath($temporaryRoot)
		$systemTemporaryRoot = [IO.Path]::GetFullPath($env:TEMP).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
		if ($resolvedTemporaryRoot.StartsWith($systemTemporaryRoot, [StringComparison]::OrdinalIgnoreCase) -and (Split-Path -Leaf $resolvedTemporaryRoot) -match '^hundouluo-windows-[0-9a-f]{32}$') {
			# Windows can retain the freshly launched EXE for a moment after exit.
			for ($attempt = 0; $attempt -lt 12; $attempt++) {
				try {
					Remove-Item -LiteralPath $resolvedTemporaryRoot -Recurse -Force -ErrorAction Stop
					break
				} catch {
					if ($attempt -eq 11) {
						Write-Warning "Temporary build directory remains locked: $resolvedTemporaryRoot"
					} else {
						Start-Sleep -Milliseconds 250
					}
				}
			}
		}
	}
}
