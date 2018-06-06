#
# DTI.VimAutomation.Output
#

function Out-Debug {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string]$Text,
    [string]$Caller
  )

  begin {
    if (-not $PSBoundParameters.ContainsKey('Debug')) {
        $DebugPreference = $PSCmdlet.GetVariableValue('DebugPreference')
    }
  }

  process {
    foreach ($str in $Text) {
      if ($Caller) {
        Write-Debug ("$(Get-Date -Format G)`t{0}`t{1}" -f $Caller,$str)
      } else {
        Write-Debug ("$(Get-Date -Format G)`t{0}" -f $str)
      }
    }
  }
}

function Out-Log {
<#
.SYNOPSIS
  Creates log entries in a file and on the console.
.DESCRIPTION
  Sends the log message provided to the log file and to the
  console using the specified message type.  Useful for quickly
  logging script progress, activity, and other messages to 
  multiple locations.
.NOTES
  Source: Automating vSphere Administration, Listing 25.7
  Note: Formerly New-LogEntry
.PARAMETER Log
  The type of log entry to make. Valid values are Output, Verbose,
  Warning, and Error. Default is Output.
.PARAMETER Message
  The string message to send to the log file and the specified
  console output.
.INPUTS
  None
.OUTPUTS
  PSCustomObject
.EXAMPLE
  New-LogEntry -Log Warning -Message "Something bad happened."
.EXAMPLE
  New-LogEntry -Message "This will output to the pipeline."
.EXAMPLE
  New-LogEntry -Log Verbose -Message "Very descriptive events."
#>
  [CmdletBinding()]
  param(
    # the message to log
    [Parameter(Mandatory=$true)]
    [String]$Message,

    # set the default to output to the next command in the pipeline
    # or to the console
    [Parameter(Mandatory=$false)]
    [ValidateSet('Output', 'Verbose', 'Warning', 'Error')]
    [String]$Log = 'Output'
  )

  process {
    # log to the same directory as the invoking script
    $logPath = "$($script:MyInvocation.MyCommand.Definition).log"

    # adding a time/date stamp to the log entry makes it easy to 
    # correlate them against actions
    $formattedMessage = "$(Get-Date -Format s) [$($Log.ToUpper())] "
    $formattedMessage += $Message

    # write the message out to the log file
    $formattedMessage | Out-File -FilePath $logPath -Encoding ascii -Append
    
    # write the message to the selected console location
    switch ($Log) {
      "Output"  { Write-Output $formattedMessage }
      "Verbose" { Write-Verbose $formattedMessage }
      "Warning" { Write-Warning $formattedMessage }
      "Error"   { Write-Error $formattedMessage }
    }
  }
}

function Out-Verbose {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string[]]$Text,
    [string]$Caller,
    [string]$Verbosity
  )

  begin {
    if (-not $PSBoundParameters.ContainsKey('Verbose')) {
        $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
    }
  }

  process {
    switch ($Verbosity.ToUpper()) {
      "LOW"    { break }
      "MEDIUM" {
                 if (([String]::IsNullOrEmpty($Global:VerboseLevel)) -or
                     ("LOW" -match $Global:VerboseLevel)) {
                   return
                 }
               }
      "HIGH"   {
                 if (([String]::IsNullOrEmpty($Global:VerboseLevel)) -or
                     ("HIGH" -notmatch $Global:VerboseLevel)) {
                   return
                 }
               }
      default  {
                 try {
                   if (($Verbosity -match "\d") -and
                       ($Verbosity -gt $Global:VerboseLevel)) {
                     return
                   }
                 } catch {
                 }
               }
    }

    foreach ($str in $Text) {
      if ($Caller) {
        Write-Verbose ("$(Get-Date -Format G)`t{0}`t{1}" -f $Caller,$str)
      } else {
        Write-Verbose ("$(Get-Date -Format G)`t{0}" -f $str)
      }
    }
  }
}

function Out-Zip {
<#
.SYNOPSIS
  Creates a .zip file of a file or folder.
.DESCRIPTION
  This function takes strings, representing file or directory paths, or the
  output of Get-ChildItem through either the pipeline or the command line
  using the -Items parameter. The ability to timestamp the zip file is
  provided, with a predefined, sortable, extension of "yyyyMMddHHmmss", using
  a 24-hour clock; or the user may supply their own, valid, datetime format
  string. Common parameters are supported such as Verbose.

  This implementation uses the native System.IO.Compression.ZipFile assembly.
  No external libs are required. However, this assembly requires that the
  subject to be compressed is a directory. This implementation uses a
  temporary directory to contain whatever is to be compressed, even if it is
  only one directory. Future revisions could check the input to see if there
  is only one directory and directly process it instead. For now, there are
  two options: copy the subject into the temp directory, which is the default
  behavior; or move the subject into the temp directory. Using the copy
  option requires an additional one to two times the subject's size during
  compression. Upon success, the temporary directory is removed with the
  duplicate subject data, leaving only the compressed file. The move option
  only requires enough additional space for the compressed file, unless files
  or folders from other partitions are being compressed as well, since they
  would be moved into the temporary directory too.  
.NOTES
  Author:  Paul Knight (paul.knight@state.de.us)
  Based on work by Bryan O'Connell, August 2013
.PARAMETER Items
  The file(s) and/or folder(s) you would like to compress, each
  represented as a string in an array.
.PARAMETER strTarget
  The location where the zip file will be created. If an old version
  exists, it will be deleted. 
.PARAMETER strCompressionLevel
  Optionally sets the compression level for your zip file. Options:
    a. fast - Higher process speed, larger file size (default option).
    b. small - Slower process speed, smaller file size.
    c. none - Fastest process speed, largest file size.
.PARAMETER bMove
  Create a zipped copy of the source file(s) and/or folder(s), then
  remove the source. The default behavior is to keep the source.
.PARAMETER strTimestampFormat
  Optionally applies a timestamp, in the specified format, to the .zip
  file name. By default, no timestamp is used. If "sortable" is
  specified, a sortable format is used; otherwise, the specified format
  string will be applied.
.EXAMPLE
  ls *.txt | Out-Zip -target C:\Users\John\Desktop\text.zip -timestamp sortable
  -compression small -move
.EXAMPLE
  "C:\Projects\wsubi" | Out-Zip -target C:\Users\John\Desktop\wsubi
.EXAMPLE
  Out-Zip -items C:\Projects\wsubi -target C:\Users\John\Desktop\wsubi
#>
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateScript({$_.GetType().Name -in "String","DirectoryInfo","FileInfo"})]
    $Items,

    [Parameter(Mandatory=$true)]
    [Alias('Target')]
    [string]$strTarget,

    [ValidateSet("fast","small","none")]
    [Alias('Compression')] 
    [string]$strCompressionLevel="fast",

    [Alias('Timestamp')]
    [string]$strTimestampFormat=$null,

    [Alias('Move')]
    [switch]$bMove=$false
  )

  begin {
#   $me = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.InvocationName)
    $me = $MyInvocation.MyCommand
    "Started Execution" | Out-Verbose -Caller $me

    # Get current directory
    $strPWD = $pwd.Path

    # Define temporary directory and redefine target as necessary
    if (-Not ([System.IO.Path]::IsPathRooted($strTarget))) {
      $strTarget = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($strTarget)
    }
    $dirTarget = Get-Item $strTarget -ErrorAction SilentlyContinue | Out-Null
    if (($dirTarget) -and ($dirTarget.PSIsContainer)) {
      # Target is an existing directory
      # Temp directory and target zip file will both be under this directory,
      # zip using the same name
      $strTmpDir = [System.IO.Path]::Combine($dirTarget.FullName, [System.IO.Path]::GetRandomFileName())
      $strTarget = [System.IO.Path]::Combine($dirTarget.FullName, $(Split-Path $strTarget -Leaf))
    } else {
      # Target is a file that may or may not already exist
      # If target does not represent a full path, use the current directory path
      $strTargetPath = Split-Path $strTarget -Parent
      if ([string]::IsNullOrEmpty($strTargetPath)) {
        $strTargetPath = $strPWD
      }
      $strTmpDir = [System.IO.Path]::Combine($strTargetPath, [System.IO.Path]::GetRandomFileName())
      $strTarget = [System.IO.Path]::Combine($strTargetPath, [System.IO.Path]::GetFileNameWithoutExtension($strTarget))
    }
    Write-Debug "TempDir: $strTmpDir"

    # Create temp directory and verify it exists
    ([System.IO.Directory]::CreateDirectory($strTmpDir)) > $null
    if (-Not (Test-Path $strTmpDir)) {
      Write-Error "Out-Zip: Creation of temp directory $strTmpDir failed."
      $host.SetShouldExit(1)
      exit
    }

    # Process timestamp, if necessary
    if ($strTimestampFormat) {
      if ($strTimestampFormat -eq "sortable") {
        $strTimestampFormat = "yyyyMMddHHmmss"
      }
      $strTimestamp = (Get-Date -Format $strTimestampFormat) -Replace "[ :/]","-"
      $strTarget += "-$strTimestamp"
    }

    # Finally, add .zip extension
    $strTarget += ".zip"
    Write-Debug "Target: $strTarget"

    # Determine compression level
    $siocCompressionLevel = $null
    switch ($strCompressionLevel) {
      "fast"    {$siocCompressionLevel = [System.IO.Compression.CompressionLevel]::Fastest} 
      "fastest" {$siocCompressionLevel = [System.IO.Compression.CompressionLevel]::Fastest} 
      "small"   {$siocCompressionLevel = [System.IO.Compression.CompressionLevel]::Optimal} 
      "optimal" {$siocCompressionLevel = [System.IO.Compression.CompressionLevel]::Optimal} 
      "none"    {$siocCompressionLevel = [System.IO.Compression.CompressionLevel]::NoCompression} 
      "nocompression" {$siocCompressionLevel = [System.IO.Compression.CompressionLevel]::NoCompression} 
    }
    Write-Debug "CompressionLevel: $siocCompressionLevel"

    # Do not include base folder in zip
    $IncludeBaseFolder = $false
  }

  process {
    foreach ($item in $Items) {
      try {
        if ($item.GetType().Name -eq 'String') {
          if (-Not ([System.IO.Path]::IsPathRooted($item))) {
            $item = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($item)
          }
          $item = Get-Item -Path $item -ErrorAction Stop
        }
        if ($bMove) {
          "Moving $($item.ToString())..." | Out-Debug -Caller $me
          Move-Item ($item.ToString()) $strTmpDir
        } else {
          "Copying $($item.ToString())..." | Out-Debug -Caller $me
          Copy-Item ($item.ToString()) $strTmpDir -Recurse
        }
      } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Error "Item Not Found: '$item'"
      } catch {
        Write-Error "`$item: $item"
        throw $Error[0].Exception
      }
    }
  }

  end {
    # Remove target if it exists
    if (Test-Path $strTarget) {
      "Replacing $strTarget..." | Out-Debug -Caller $me
      Remove-Item ($strTarget) -Force -Recurse
    }

    # Perform compression of temporary directory to target
    "Compressing..." | Out-Debug -Caller $me
    [Reflection.Assembly]::LoadWithPartialName( "System.IO.Compression.FileSystem" ) | Out-Null
    [System.IO.Compression.ZipFile]::CreateFromDirectory($strTmpDir, $strTarget, $siocCompressionLevel, $IncludeBaseFolder) | Out-Null

    # Cleanup if compression was successful
    if (Test-Path $strTarget) {
      "Cleaning up..." | Out-Debug -Caller $me
      Remove-Item -Path $strTmpDir -Force -Recurse
    }

    "Finished execution" | Out-Verbose -Caller $me
  }
}


#
# Initialize Module
# 
#. Initialize-Module
Export-ModuleMember Out-Debug
Export-ModuleMember Out-Log
Export-ModuleMember Out-Verbose
Export-ModuleMember Out-Zip
