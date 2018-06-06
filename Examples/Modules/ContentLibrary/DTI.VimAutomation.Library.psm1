#
# DTI.VimAutomation.Library
#
# NOTE: Function names do *not* include "Content" because VMware already has
#       "Get-ContentLibraryItem", so this avoids collisions (but this one's 
#       better ;)
#
# Some functions are reimplementations of the same or similar funtions by
# William Lam, in his fine blog, which can be found here:
#
# https://www.virtuallyghetto.com/2017/07/vsphere-content-library-powercli-community-module.html
#

<#
.SYNOPSIS
  Library - describes a Content Library
.DESCRIPTION
  This class contains the information about a Content Library.
.NOTES
  Author: Paul Knight (paul.knight@state.de.us)
.PARAMETER Name
  The human-readable name of this library.
.PARAMETER Id
  Identifier which uniquely identifies this library.
.PARAMETER Type
  The type of this library which determines what additional services and
  information can be available.
.PARAMETER Description
  A human-readable description of this library.
.PARAMETER Datastore
  The human-readable name of the backing datastore where this library is
  located. Multiple storage locations are not currently supported.
.PARAMETER Published
  Whether local library is publically available for consumption by subscribers.
.PARAMETER PublishedURL
  The URL to which the library metadata is published by the Content Library
  Service. This value can be used to set the subscription URL property when
  creating a subscribed library.
.PARAMETER JSONPersistence 
  Identifies whether library and its items' metadata are persisted in storage
  as JSON files. This flag only applies if the local library is published and
  its storage backing type is "OTHER". Enabling JSON persistence allows you to
  synchronize a subscribed library manually instead of over HTTP. You copy the
  local library content and metadata to another storage backing manually and
  then create a subscribed library referencing the location of the library JSON
  file in the subscription URL. When the subscribed library's storage URI
  matches the subscription URL, files do not need to be copied to the
  subscribed library.
.PARAMETER SubscribedURL
  The URL that is the source of the published metadata to which the library
  is subscribed.
.PARAMETER Version
  A version number which is updated on metadata changes. This allows clients to
  detect concurrent updates and prevent accidental clobbering of data. This
  value represents a number that is incremented every time library properties
  such as name or description are changed. It is not incremented by changes to
  items within the library, including adding or removal of items. It is also
  not affected by tagging the library.
.PARAMETER Created
  The date and time when this library was created.
.PARAMETER Modified
  The date and time the library was last modified.
.PARAMETER Synced
  The date and time the library was last synchronized.
.PARAMETER ExtensionData
  The raw data from the Content Library API.
#>
class Library {
  [string]$Name
  [string]$Id
  [string]$Type
  [string]$Description
  [string]$Datastore
  [bool]$Published
  [uri]$PublishedURL
  [bool]$JSONPersistence
  [uri]$SubscribedURL
  [string]$Version
  [nullable[datetime]]$Created
  [nullable[datetime]]$Modified
  [nullable[datetime]]$Synced
  [PSObject]$ExtensionData

  # Constructon
  Library(
    [PSObject]$library,
    [VMware.VimAutomation.ViCore.Impl.V1.DatastoreManagement.DatastoreImpl]$datastore
  ) {
    # Assign members
    $this.Name = $library.name
    $this.Id   = $library.id
    $this.Type = $library.type
    $this.Description = $library.description
    $this.Datastore   = $datastore.Name
    $this.Published   = $library.publish_info.published
    $this.Version     = $library.version
    $this.Created     = $library.creation_time
    $this.Modified    = $library.last_modified_time
    $this.Synced      = $library.last_sync_time
    $this.ExtensionData= $library

    if ($library.publish_info.published) {
      $this.PublishedURL   = $library.publish_info.publish_url
      $this.JSONPersistence= $library.publish_info.persist_json_enabled
    } else {
      $this.PublishedURL   = $null
      $this.JSONPersistence= $null
    }

    if ($library.subscription_info) {
      $this.SubscribedURL  = $library.subscription_info.subscription_url
    } else {
      $this.SubscribedURL  = $null
    }

    # Define default properties
    $defaultProperties = @('Name','Type','Description')
    $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
    $this | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    $this | Add-Member ScriptMethod ToString { $this.Name } -Force
  }
}

<#
.SYNOPSIS
  LibraryItem - describes a Content Library Item
.DESCRIPTION
  This class contains the information about a Content Library Item.
.NOTES
  Author: Paul Knight (paul.knight@state.de.us)
.PARAMETER Name
  The human-readable name of this library item.
.PARAMETER Id
  A unique identifier for this library item.
.PARAMETER Type
  An optional identifier for the type adapter to use.
.PARAMETER Description
  A human-readable description for this library item.
.PARAMETER Size
  The item's size in bytes. The size is the sum of the size used on the storage
  backing for all the files in the item. When the item is not cached, the size
  is 0.
.PARAMETER Cached
  The status indicating whether the library item is on disk or not. The library
  item is cached when all its files are on disk.
.PARAMETER SourceId
  The identifier of the Item Model to which this item is synchronized, if the
  item belongs to a subscribed library. The item is unset for a library item
  that belongs to a local library.
.PARAMETER Library
  The Library object to which the item belongs.
.PARAMETER Files
  An array of LibraryItemFile objects that describe the files contained in the
  item.
.PARAMETER ContentVersion
  The version of the file content list of this library item.
.PARAMETER MetadataVersion
  A version number for the metadata of this library item. This value is
  incremented with each change to the metadata of this item. Changes to name,
  description, and so on will increment this value. The value is not
  incremented by changes to the content or tags of the item or the library that
  owns it.
.PARAMETER Version
  A version number that is updated on metadata changes. This value is used to
  validate update requests to provide optimistic concurrency of changes. This
  value represents a number that is incremented by changes to the file content
  of the library item properties, such as name or description, are changed. It
  is not incremented by changes to the file content of the library item,
  including adding or removing files. It is also not affected by tagging the
  library item.
.PARAMETER Created
  The date and time when this library item was created.
.PARAMETER Modified
  The date and time when this library item was last modified.
.PARAMETER Synced
  The date and time when this library item was last synchronized.
.PARAMETER ExtensionData
  The raw data from the Content Library Item API.
#>
class LibraryItem {
  [string]$Name
  [string]$Id
  [string]$Type
  [string]$Description
  [long]$Size
  [bool]$Cached
  [string]$SourceId
  [Library]$Library
  [LibraryItemFile[]]$Files
  [string]$ContentVersion
  [string]$MetadataVersion
  [string]$Version
  [nullable[datetime]]$Created
  [nullable[datetime]]$Modified
  [nullable[datetime]]$Synced
  [PSObject]$ExtensionData
  hidden [PSObject]$libraryItemFileService

  # Constructor
  LibraryItem(
    [Library]$Library,
    [PSObject]$Item
  ) {
    # Assign members
    $this.Name = $Item.name
    $this.Id   = $Item.id
    $this.Type = $Item.type
    $this.Description = $Item.description
    $this.Size = $Item.size
    $this.Cached   = $Item.cached
    $this.Library  = $Library
    $this.ContentVersion  = $Item.content_version
    $this.MetadataVersion = $Item.metadata_version
    $this.Version  = $Item.version
    $this.Created  = $Item.creation_time
    $this.Modified = $Item.last_modified_time
    $this.Synced   = $Item.last_sync_time
    $this.ExtensionData = $Item
    $this.libraryItemFileService = Get-CisService com.vmware.content.library.item.file -Verbose:$false

    $this.GetFiles()

    # Define default properties
    $defaultProperties = @('Name','Type','Description')
    $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
    $this | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    $this | Add-Member ScriptMethod ToString { $this.Name } -Force
  }

  hidden [void]GetFiles() {
    $objs = $this.libraryItemFileService.list($this.Id)
    $this.Files = foreach ($obj in $objs) {
      [LibraryItemFile]::new($obj)
    }
  }

  [void]Refresh() {
    $this.GetFiles()
    return
  }
}

<#
.SYNOPSIS
  LibraryItemFile - describes a Content Library Item File
.DESCRIPTION
  This class contains the information about a Content Library Item File.
.NOTES
  Author: Paul Knight (paul.knight@state.de.us)
.PARAMETER Name
  The name of the file, which is unique within the library item for each file.
.PARAMETER Size
  The item's size in bytes. The file size is the storage used and not the
  uploaded or provisioned size. When the item is not cached, the size is 0.
.PARAMETER Cached
  Indicates whether the file is on disk or not.
.PARAMETER Checksum
  A checksum for validating the content of the file. This value can be used to
  verify that a transfer was completed without errors.
.PARAMETER Item
  The LibraryItem object to which the file belongs.
.PARAMETER Version
  The version of this file, incremented when a new copy of the file is
  uploaded.
.PARAMETER ExtensionData
  The raw data from the Content Library Item File API.
#>
class LibraryItemFile {
  [string]$Name
  [long]$Size
  [long]$Checksum
  [string]$Version
  [bool]$Cached
  [PSObject]$ExtensionData

  # Constructor
  LibraryItemFile(
    [PSObject]$file
  ) {
    # Assign members
    $this.Name = $file.name
    $this.Size = $file.size
    $this.Checksum= $file.checksum_info
    $this.Version = $file.version
    $this.Cached  = $file.cached
    $this.ExtensionData = $file

    # Define default properties
    $defaultProperties = @('Name','Size','Version','Cached')
    $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
    $this | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    $this | Add-Member ScriptMethod ToString { $this.Name } -Force
  }
}

<#
.SYNOPSIS
  LibraryUpdateSession
.DESCRIPTION
  This class contains the information about a Content Library Item Update
  Session.

  Methods:
    Cancel - Cancels an update session
      This function will free up any temporary resources currently
      associated with the session. This operation is not allowed if the
      session has been already completed. Cancelling an update session will
      cancel any in progress transfers (either uploaded by the client or
      pulled by the server). Any content that has been already received will
      be scheduled for deletion.
    Complete - Completes an update session
      This indicates that the client has finished making all the changes
      required to the underlying library item. If the client is pushing the
      content to the server, the library item will be updated once this call
      returns. If the server is pulling the content, the call may return
      before the changes become visible. In that case, the client can track
      the session to know when the server is done. This operation requires
      the session to be in the ACTIVE state. Depending on the type of the
      library item associated with this session, a type adapter may be
      invoked to verify the validity of the files uploaded. The user can
      explicitly validate the session before completing the session by using
      the validate operation. Modifications are not visible to other clients
      unless the session is completed and all necessary files have been
      received.
    Delete - Deletes an update session 
      This removes the session and all information associated with it.
      Removing an update session leaves any current transfers for that
      session in an indeterminate state (there is no guarantee that the
      server will terminate the transfers, or that the transfers can be
      completed). However there will no longer be a means of inspecting the
      status of those uploads except by seeing the effect on the library
      item. Update sessions for which there is no upload activity or which
      are complete will automatically be deleted after a period of time.
    Fail - Terminates an update session with error message
      This is useful in transmitting client-side failures, like inability to
      access a file, to the server side.
    KeepAlive - Keeps an update session alive
      If there is no activity for an update session after a period of time,
      the update session will expire, then be deleted. The update session
      expiration timeout is configurable in the Content Library Service
      system configuration. The default is five minutes.  Invoking this
      operation enables a client to specifically extend the lifetime of the
      update session.
.NOTES
  Author: Paul Knight (paul.knight@state.de.us)
.PARAMETER Id
  A unique identifier for this update session.
.PARAMETER Name
  The human-readable name of the item being updated by this session.
.PARAMETER Item
  The LibraryItem object associated with this update session.
.PARAMETER State
  The state of the update session: ACTIVE, ERROR, CANCELED, DONE or DEFUNCT.
  If the update session has been deleted from the infrastructure, subsequent
  refreshes of the object will assign DEFUNCT to the state, indicating it is
  no longer found.
.PARAMETER Progress
  The percentage completion of the update.
.PARAMETER ErrorMessage
  An object containing information about the last error, including the error
  message.
.PARAMETER ServerError
  If the error is a CisServerException, the ServerError text is saved too.
.PARAMETER Expires
  Indicates the time after which the session will expire. The session is
  guaranteed not to expire earlier than this time.
.PARAMETER ExtensionData
  The raw data from the Content Library Item Update Session API.
#>
class LibraryUpdateSession {
  [string]$Id
  [string]$Name
  [LibraryItem]$Item
  [string]$State
  [nullable[long]]$Progress
  [LibraryUpdateSessionFile[]]$Files
  [Object]$ErrorMessage
  [Object]$ServerError
  [nullable[datetime]]$Expires
  [PSObject]$ExtensionData
  hidden [PSObject]$libraryItemUpdateSessionService
  hidden [PSObject]$libraryItemUpdateSessionFileService

  # Constructor
  LibraryUpdateSession(
    [LibraryItem]$Item,
    [PSObject]$session
  ) {
    # Assign members
    $this.Id = $session.id
    $this.Name = $Item.Name
    $this.Item = $Item
    $this.State = $session.state
    $this.Progress = $session.client_progress
    $this.ErrorMessage = $session.error_message
    $this.Expires = $session.expiration_time
    $this.ExtensionData = $session
    $this.libraryItemUpdateSessionService = Get-CisService com.vmware.content.library.item.update_session -Verbose:$false
    $this.libraryItemUpdateSessionFileService = Get-CisService com.vmware.content.library.item.updatesession.file -Verbose:$false

    $this.GetFiles()

    # Define default properties
    $defaultProperties = @('Name','Progress','State','Expires')
    $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
    $this | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    $this | Add-Member ScriptMethod ToString { $this.Id } -Force
  }

  # Get LibraryUpdateSessionFile objects
  hidden [void]GetFiles(){
    $objs = $this.libraryItemUpdateSessionFileService.list($this.Id)
    $this.Files = foreach ($obj in $objs) {
      [LibraryUpdateSessionFile]::new($obj)
    }
  }

  # Refresh state information
  [void]Refresh(){
    try {
      $session = $this.libraryItemUpdateSessionService.get($this.Id)
      $this.GetFiles()
      $this.State = $session.state
      $this.Progress = $session.client_progress
      $this.ErrorMessage = $session.error_message
      $this.ExtensionData = $session
    } catch {
      $this.State = "DEFUNCT"
    }
    return
  }

  # Cancel this update session
  [void]Cancel(){
    if ($this.State -eq "DEFUNCT") {
      throw New-Object System.InvalidOperationException "Session no longer exists."
    } else {
      try {
        $this.libraryItemUpdateSessionService.cancel($this.Id)
      } catch {
        $this.ServerError = $_.Exception.ServerError
        throw
      } finally {
        $this.Refresh()
      }
    }
    return
  }

  # Complete this update session
  [void]Complete(){
    if ($this.State -eq "DEFUNCT") {
      throw New-Object System.InvalidOperationException "Session no longer exists."
    } else {
      try {
        $this.libraryItemUpdateSessionService.complete($this.Id)
      } catch {
        $this.ServerError = $_.Exception.ServerError
        throw
      } finally {
        $this.Refresh()
      }
    }
    return
  }

  # Delete this update session
  [void]Delete(){
    if ($this.State -eq "DEFUNCT") {
      throw New-Object System.InvalidOperationException "Session no longer exists."
    } else {
      try {
        $this.libraryItemUpdateSessionService.delete($this.Id)
      } catch {
        $this.ServerError = $_.Exception.ServerError
        throw
      } finally {
        $this.Refresh()
      }
    }
    return
  }

  # Fail this update session
  [void]Fail([string]$ErrorMessage){
    if ($this.State -eq "DEFUNCT") {
      throw New-Object System.InvalidOperationException "Session no longer exists."
    } else {
      try {
        $this.libraryItemUpdateSessionService.fail($this.Id,$ErrorMessage)
      } catch {
        $this.ServerError = $_.Exception.ServerError
        throw
      } finally {
        $this.Refresh()
      }
    }
    return
  }

  # Keeps this update session alive
  [void]KeepAlive([nullable[long]]$Progress){
    if ($this.State -eq "DEFUNCT") {
      throw New-Object System.InvalidOperationException "Session no longer exists."
    } else {
      try {
        $this.libraryItemUpdateSessionService.keep_alive($this.Id,$Progress)
      } catch {
        $this.ServerError = $_.Exception.ServerError
        throw
      } finally {
        $this.Refresh()
      }
    }
    return
  }
}

<#
.SYNOPSIS
  LibraryUpdateSessionFile
.DESCRIPTION
  This class contains information about files being changed in a Content Library Item.
.PARAMETER Name
.PARAMETER Size
.PARAMETER Checksum
.PARAMETER SourceType
.PARAMETER SourceEndpoint
.PARAMETER UploadEndpoint
.PARAMETER BytesTransferred
.PARAMETER Status
.PARAMETER ErrorMessage
.PARAMETER ExtensionData
#>
class LibraryUpdateSessionFile {
  [string]$Name
  [nullable[long]]$Size
  [nullable[long]]$Checksum
  [string]$SourceType
  [PSObject]$SourceEndpoint
  [PSObject]$UploadEndpoint
  [long]$BytesTransferred
  [string]$Status
  [PSObject]$ErrorMessage
  [PSObject]$ExtensionData

  #Constructor
  LibraryUpdateSessionFile(
    [PSObject]$sessionFile
  ) {
    # Assign members
    $this.Name = $sessionFile.name
    $this.Size = $sessionFile.size
    $this.Checksum = $sessionFile.checksum_info
    $this.SourceType = $sessionFile.source_type
    $this.SourceEndpoint = $sessionFile.source_endpoint
    $this.UploadEndpoint = $sessionFile.upload_endpoint
    $this.BytesTransferred = $sessionFile.bytes_transferred
    $this.Status = $sessionFile.status
    $this.ErrorMessage = $sessionFile.error_message
    $this.ExtensionData = $sessionFile

    # Define default properties
    $defaultProperties = @('Name','Status','BytesTransferred')
    $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
    $this | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    $this | Add-Member ScriptMethod ToString { $this.Name } -Force
  }
}

<#
.SYNOPSIS
  Lists Content Libraries
.DESCRIPTION
  This function lists either the specified vSphere Content Libaries, or, if
  none are specified, all available libraries.
.NOTES
  Author: Paul Knight (paul.knight@state.de.us)
  Based on work by William Lam
.OUTPUTS
  Library
.PARAMETER Name
  The name of a vSphere Content Library. A list of names can be provided or piped in.
.EXAMPLE
  Get-Library
.EXAMPLE
  Get-Library -Name Test
#>
function Get-Library {
  [OutputType([Library])]
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [string]$Name
  )

  begin {

    function BuildLibrary($lib) {
      $dsID= $lib.storage_backings.datastore_id
      $datastore = Get-Datastore | Where Id -match $dsID
      return [Library]::new($library,$datastore)
    }

    "Start execution" | Out-Verbose -Caller Get-Library

    $libraryService = Get-CisService com.vmware.content.library -Verbose:$false
    $libaryIDs = $libraryService.list()
  }

  process {
    foreach ($libraryID in $libaryIDs) {
      $library = $libraryService.get($libraryID)

      if (!$Name) {
        BuildLibrary($library)
      } else {
        foreach ($str in $Name) {
          if ($library.name -eq $str) {
            BuildLibrary($library)
          }
        }
      }
    }
  }

  end {
    "Finished execution" | Out-Verbose -Caller Get-Library
  }
}


#
# Local Content Library Cmdlets
#

<#
.SYNOPSIS
  Set JSONS persistence on a library
.DESCRIPTION
  This function updates the JSON persistence property on a specified Content
  Library.
.NOTES
  Author: Paul Knight (paul.knight@state.de.us)
  Based on work by William Lam
.PARAMETER Library
  The vSphere Content Library. Can be specified by name, object or piped in.
.PARAMETER Persist
  Enables JSON persistence on the specified library. The default is to disable
  persistence.
.EXAMPLE
  Set-Library -Library Test -Persist
.EXAMPLE
  Set-Library -Library Test -NoPersist
#>
function Set-Library {
  [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="Medium")]
  param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [PSObject]$Library,
    [Parameter(ParameterSetName='Persist')]
    [switch]$Persist,
    [Parameter(ParameterSetName='NoPersist')]
    [switch]$NoPersist
  )

  begin {
    "Started execution" | Out-Verbose -Caller Set-Library
    $localLibraryService = Get-CisService com.vmware.content.local_library -Verbose:$false
    if ($NoPersist) {
      $Persist = $false
    }
  }

  process {
    foreach ($lib in $Library) {
      $libObj = $null
      switch ($lib.GetType().Name) {
        "Library" {$libObj = $lib}
        "String"  {$libObj = Get-Library -Name $lib}
        default   {throw New-Object System.ArgumentException `
                    "Unsupported object: $($lib.GetType().Name)"
                  }
      }

      if (!$libObj) {
        Write-Warning "Library '$($lib.ToString())' not found."
        continue
      } else {
        "Library: $($libObj.Name)" | Out-Verbose -Caller Set-Library -Verbosity Medium
      }

      $updateSpec = $localLibraryService.Help.update.update_spec.Create()
      $updateSpec.type = $libObj.Type
      $updateSpec.publish_info.authentication_method = $libObj.ExtensionData.publish_info.authentication_method
      $updateSpec.publish_info.persist_json_enabled = $Persist

      if ($PSCmdlet.ShouldProcess($libObj.Name)) {
        "Setting JSON Persistence for $($libObj.Name) to $($Persist)" | Out-Verbose -Caller Set-Library -Verbosity Medium
        $localLibraryService.update($libObj.Id,$updateSpec)
      } else {
        "JSON Persistence for $($libObj.Name) would be set $($Persist)" | Out-Verbose -Caller Set-Library -Verbosity Medium
      }
    } 
  }

  end {
    "Finished execution" | Out-Verbose -Caller Set-Library
  }
}

<#
.SYNOPSIS
  Creates a new Local Content Library
.NOTES
  Author: Paul Knight (paul.knight@state.de.us)
  Based on work by William Lam
.DESCRIPTION
  This function creates a new local Content Library which can be published for others to
  then consume as subscribers.
.OUTPUTS
  [Library]
.PARAMETER Name
  The name of the new vSphere Content Library.
.PARAMETER Datastore
  The Datastore to store the Content Library.
.PARAMETER Publish
  Identifies whether the library should be published. This is required for JSON
  Peristence.
.PARAMETER Persist
  Identifies whether to enable JSON Persistence, which enables external
  replication of Content Library.
.EXAMPLE
  New-LocalLibrary -Name Foo `
                   -Datastore iSCSI-01 `
                   -Publish $true
.EXAMPLE
  New-LocalLibrary -Name Foo `
                   -Datastore iSCSI-01 `
                   -Publish $true `
                   -Persist $true
#>
function New-LocalLibrary {
  [OutputType([Library])]
  [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="Medium")]
  param(
    [Parameter(Mandatory=$true)]
    [string]$Name,
    [Parameter(Mandatory=$true)]
    [PSObject]$Datastore,
    [Switch]$Publish,
    [Switch]$Persist
  )

  begin {
    "Started execution" | Out-Verbose -Caller New-LocalLibrary
    $dsObj = $null
    $localLibraryService = Get-CisService -Name com.vmware.content.local_library -Verbose:$false
    $UniqueChangeId = [guid]::NewGuid().tostring()
  }

  process {
    # Get Datastore object
    switch ($Datastore.GetType().Name) {
      "VMware.VimAutomation.ViCore.Impl.V1.DatastoreManagement.VmfsDatastoreImpl" {$dsObj = $Datastore}
      "VMware.VimAutomation.ViCore.Impl.V1.DatastoreManagement.NasDatastoreImpl"  {$dsObj = $Datastore}
      "String"         {$dsObj = Get-Datastore -Name $Datastore}
      default          {throw New-Object System.ArgumentException `
                         "Unsupported datastore object: $($Library.GetType().Name)"
                       }
    }
    if (!$dsObj) {
      throw New-Object System.ArgumentException "Datastore '$($Datastore.ToString())' not found."
    }
    $dsId = $dsObj.ExtensionData.MoRef.Value

    $StorageSpec = [PSCustomObject] @{
      datastore_id = $dsId;
      type         = "DATASTORE";
    }

    $createSpec = $localLibraryService.Help.create.create_spec.Create()
    $createSpec.name = $Name
    $addResults = $createSpec.storage_backings.Add($StorageSpec)
    $createSpec.publish_info.authentication_method = "NONE"
    $createSpec.publish_info.persist_json_enabled = $Persist
    $createSpec.publish_info.published = $Publish
    $createSpec.type = "LOCAL"

    if ($PSCmdlet.ShouldProcess($Name)) {
      "Creating Local Content Library $Name..." | Out-Verbose -Caller New-LocalLibrary -Verbosity Medium
      $lib = $localLibraryService.create($UniqueChangeId,$createSpec)
      if ($lib) {
        Get-Library -Name $Name
      } else {
        Write-Error "Failed to create $Name as Local Content Library."
        return
      }
    } else {
      $str = "Local Library $Name would be created"
      if ($Publish) {
        $str += ", published"
      }
      if ($Persist) {
        $str += ", and persisted"
      }
      $str | Out-Verbose -Caller New-LocalLibrary -Verbosity Medium
    }
  }

  end {
    "Finished execution" | Out-Verbose -Caller New-LocalLibrary
  }
}

<#
.SYNOPSIS
  Deletes local Content Library
.NOTES
  Author: Paul Knight (paul.knight@state.de.us)
  Based on work by William Lam
.DESCRIPTION
  This function deletes a Local Content Library. Supports -confirm, -verbose and -whatif.
.PARAMETER Library
  The vSphere Content Library to delete. Can be specified by name, object or piped in.
.EXAMPLE
  Remove-LocalLibrary -Library Bar
#>
Function Remove-LocalLibrary {
  [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="High")]
  param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [PSObject]$Library
  )

  begin {
    "Started execution" | Out-Verbose -Caller Remove-LocalLibrary
    $localLibraryService = Get-CisService com.vmware.content.local_library -Verbose:$false
  }

  process {
    foreach ($lib in $Library) {
      $libObj = $null
      # Get local Content Library object
      switch ($lib.GetType().Name) {
        "Library" {$libObj = $lib}
        "String"         {$libObj = Get-Library -Name $lib}
        default          {throw New-Object System.ArgumentException `
                           "Unsupported library object: $($lib.GetType().Name)"
                         }
      }
      if (!$libObj) {
        Write-Warning "Library '$($lib.ToString())' not found."
        continue
      }

      if ($PSCmdlet.ShouldProcess($libObj.Name)) {
        Write-Host "Deleting Local Content Library $LibraryName ..."
        $localLibraryService.delete($library.id)
      } else {
        "Library $($libObj.Name) would be deleted." | Out-Verbose -Caller Remove-LocalLibrary -Verbosity Medium
      }
    }
  }

  end {
    "Finished execution" | Out-Verbose -Caller Remove-LocalLibrary
  }
}


#
# Subscribed Content Library Cmdlets
#

<#
.SYNOPSIS
  Creates a new Subscriber Content Library
.DESCRIPTION
  This function creates a new Subscriber Content Library from a JSON Persisted
  Content Library that has been externally replicated.
.NOTES
  Author: Paul Knight (paul.knight@state.de.us)
  Based on work by William Lam
.OUTPUTS
  [Library]
.PARAMETER Library
  The externally replicated vSphere Content Library. Can be specified by name, object, or
  piped in, but only the first object will be recognized.
.PARAMETER Datastore
  The Datastore which contains JSON persisted configuration file
.PARAMETER Name
  The name of the new vSphere Content Library
.PARAMETER AutoSync
  Indicates whether content should be automatically synchronized
.PARAMETER OnDemand
  Only sync content when requested
.EXAMPLE
  New-SubscribedLibrary -LibraryName Bar `
                        -DatastoreName iSCSI-02 `
                        -SubscribeLibraryName myExtReplicatedLibrary
.EXAMPLE
  New-SubscribedLibrary -LibraryName Bar `
                        -DatastoreName iSCSI-02 `
                        -SubscribeLibraryName myExtReplicatedLibrary `
                        -AutoSync $false `
                        -OnDemand $true
#>
function New-SubscribedLibrary {
  [OutputType([Library])]
  [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="Medium")]
  param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [PSObject]$Library,
    [Parameter(Mandatory=$true)]
    [PSObject]$Datastore,
    [Parameter(Mandatory=$true)]
    [string]$Name,
    [switch]$AutoSync,
    [switch]$OnDemand
  )

  begin {
    "Started execution" | Out-Verbose -Caller New-SubscribedLibrary
    $libObj = $null
    $dsObj  = $null
    $subscribedLibraryService = Get-CisService com.vmware.content.subscribed_library -Verbose:$false
    $UniqueChangeId = [guid]::NewGuid().tostring()
  }

  process {
    # Get local Content Library object
    switch ($Library.GetType().Name) {
      "Library" {$libObj = $Library}
      "String"         {$libObj = Get-Library -Name $Library}
      default          {throw New-Object System.ArgumentException `
                         "Unsupported library object: $($Library.GetType().Name)"
                       }
    }
    if (!$libObj) {
      throw New-Object System.ArgumentException "Library '$($Library.ToString())' not found."
    }

    # Get Datastore object
    switch ($Datastore.GetType().Name) {
      "VMware.VimAutomation.ViCore.Impl.V1.DatastoreManagement.VmfsDatastoreImpl" {$dsObj = $Datastore}
      "VMware.VimAutomation.ViCore.Impl.V1.DatastoreManagement.NasDatastoreImpl"  {$dsObj = $Datastore}
      "String"         {$dsObj = Get-Datastore -Name $Datastore}
      default          {throw New-Object System.ArgumentException `
                         "Unsupported datastore object: $($Datastore.GetType().Name)"
                       }
    }
    if (!$dsObj) {
      throw System.ArgumentException "Datastore '$($Datastore.ToString())' not found."
    }
    $dsId = $dsObj.ExtensionData.MoRef.Value
    $dsUrl= $dsObj.ExtensionData.Info.Url
    $subscribeUrl = $dsUrl + $libObj.Name + "/lib.json"
 
    $storageSpec = [PSCustomObject] @{
      datastore_id = $dsId;
      type         = "DATASTORE";
    }

    $createSpec = $subscribeLibraryService.Help.create.create_spec.Create()
    $createSpec.name = $Name
    $addResults = $createSpec.storage_backings.Add($storageSpec)
    $createSpec.subscription_info.automatic_sync_enabled = $AutoSync
    $createSpec.subscription_info.on_demand = $OnDemand
    $createSpec.subscription_info.subscription_url = $subscribeUrl
    $createSpec.subscription_info.authentication_method = "NONE"
    $createSpec.type = "SUBSCRIBED"

    if ($PSCmdlet.ShouldProcess($Name)) {
      "Creating new externally replicated library $($Name) ..." | Out-Verbose -Caller New-SubscribedLibrary -Verbosity Medium
      $subLibrary = $subscribeLibraryService.create($UniqueChangeId,$createSpec)
      if ($subLibrary) {
        Get-Library -Name $Name
      } else {
        Write-Error "Failed to create Content Library."
        return
      }
    } else {
      $str = "Subscribed Library $Name would be created"
      if ($AutoSync) {
        $str += ", auto synced"
      }
      if ($OnDemand) {
        $str += ", and on demand"
      }
      $str | Out-Verbose -Caller New-SubscribedLibrary -Verbosity Medium
    }
  }

  end {
    "Finished execution" | Out-Verbose -Caller New-SubscribedLibrary
  }
}

<#
.SYNOPSIS
  Deletes a Subscriber Content Library
.DESCRIPTION
  This function deletes a Subscriber Content Library
.NOTES
  Author: Paul Knight (paul.knight@state.de.us)
  Based on work by William Lam
.PARAMETER Library
  The name of the new vSphere Content Library to delete
.EXAMPLE
  Remove-SubscribedLibrary -Library Bar
#>
function Remove-SubscribedLibrary {
  [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="High")]
  param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [PSObject]$Library
  )

  begin {
    "Started execution" | Out-Verbose -Caller Remove-SubscribedLibrary
    $subscribeLibraryService = Get-CisService com.vmware.content.subscribed_library -Verbose:$false
  }

  process {
    foreach ($lib in $Library) {
      $libObj = $null
      # Get local Content Library object
      switch ($lib.GetType().Name) {
        "Library" {$libObj = $lib}
        "String"         {$libObj = Get-Library -Name $lib}
        default          {throw New-Object System.ArgumentException `
                           "Unsupported library object: $($lib.GetType().Name)"
                         }
      }
      if (!$libObj) {
        Write-Warning "Library '$($lib.ToString())' not found."
        continue
      }

      if ($PSCmdlet.ShouldProcess($libObj.Name)) {
        $subscribeLibraryService.delete($library.id)
      } else {
        "Library $($libObj.Name) would be deleted." | Out-Verbose -Caller Remove-SubscribedLibrary -Verbosity Medium
      }
    }
  }

  end {
    "Finished execution" | Out-Verbose -Caller Remove-SubscribedLibrary
  }
}


#
# Library Item Cmdlets
#

<#
.SYNOPSIS
  Lists items in a Content Library
.DESCRIPTION
  This function lists items within a given vSphere Content Library. If no items are
  specified, all items will be listed.
.NOTES
  Author: Paul Knight (paul.knight@state.de.us)
  Based on work by William Lam
.OUTPUTS
  LibraryItem
.PARAMETER Library
  The vSphere Content Library. Can be specified by name, object or piped in.
.PARAMETER Id
  A unique id of an item. If specified, the Item and Regex parameters are ignored.
.PARAMETER Item
  The name of the items in the Content Library, specified using wildcards if desired.
.PARAMETER Regex
  Use a case-sensitive regular expression instead of wildcards for identifying items.
.EXAMPLE
  Get-LibraryItem -Library Test
.EXAMPLE
  Get-LibraryItem -Library Test -Name TinyPhotonVM
#>
function Get-LibraryItem {
  [OutputType([LibraryItem])]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true,ParameterSetName='Id')]
    [String]$Id,
    [Parameter(ValueFromPipeline=$true,ParameterSetName='Name')]
    [PSObject]$Library,
    [Parameter(ParameterSetName='Name')]
    [String]$Item = "*",
    [Parameter(ParameterSetName='Name')]
    [Switch]$Regex
  )

  begin {
    "Started execution" | Out-Verbose -Caller Get-LibraryItem
    $libraryItemService = Get-CisService com.vmware.content.library.item -Verbose:$false
  }

  process {
    if ($Id) {
      $obj = $libraryItemService.get($Id)
      [LibraryItem]::new($libObj,$obj)
    } else {
      if (!$Library) {
        $Library = Get-Library
      }
      foreach ($lib in $Library) {
        $libObj = $null
        switch ($lib.GetType().Name) {
          "Library" {$libObj = $lib}
          "String"  {$libObj = Get-Library -Name $lib}
          default   {throw New-Object System.ArgumentException `
                      "Unsupported object: $($lib.GetType().Name)"
                    }
        }
        if (!$libObj) {
          Write-Warning "Library '$($lib.ToString())' not found."
          continue
        }
        "Library: $($libObj.Name)" | Out-Verbose -Caller Get-LibraryItem -Verbosity Medium
        "Items  : '$Item'" | Out-Verbose -Caller Get-LibraryItem -Verbosity Medium

        $itemIDs = $libraryItemService.list($libObj.Id)
        foreach ($itemID in $itemIDs) {
          $obj = $libraryItemService.get($itemID)
          if ((!$Regex -and ($obj.name -like $Item)) -or
              ($Regex -and ($obj.name -cmatch $Item))) {
            [LibraryItem]::new($libObj,$obj)
          }
        }
      }
    }
  }

  end {
    "Finished execution" | Out-Verbose -Caller Get-LibraryItem
  }
}

<#
.SYNOPSIS
  Copies items from one Content Library to another
.DESCRIPTION
  This function copies the specified library items from one Content Library to another.
  The items in the destination library will have the same names as they did in the source
  library. Optionally, items can be removed from the source as they are copied. If an item
  already exists in the destination library, there is an option to force its removal before
  attempting to copy.
.NOTES
  Author: Paul Knight (paul.knight@state.de.us)
  Based on work by William Lam
.PARAMETER Source
  The source Content Library to copy from. This can be a name, object or multiples of
  either, and can be piped in.
.PARAMETER Destination
  The desintation Content Library to copy to. Like Highlander, there can be only one, but
  it too can be a name or an object.
.PARAMETER Item
  The name of the items to be copied, specified using wildcards if desired. If none are
  specified, then all items will be copied from the source.
.PARAMETER Force
  If an item already exists in the destination library, delete it and copy the source item.
.PARAMETER Ignore
  Continue processing all specified source libraries if some are missing, or items are
  not found.
.PARAMETER Move
  Indicates that items should be deleted from the source Content Library after successfully
  copying them to the destination Content Library 
.PARAMETER Regex
  Use a case-sensitive regular expression instead of wildcards for identifying items.
.EXAMPLE
  Copy-Library -Source Foo `
               -Destination Bar
.EXAMPLE
  Copy-Library -Source Foo `
               -Destination Bar `
               -Move
#>
function Copy-LibraryItem {
  [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="Medium")]
  param(
    [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
    [PSObject]$Source,
    [Parameter(Position=1,Mandatory=$true)]
    [PSObject]$Destination,
    [Parameter(Position=2)]
    [string]$Item = "*",
    [Switch]$Force,
    [Switch]$Ignore,
    [Switch]$Move,
    [Switch]$Regex
  )

  begin {
    "Started execution" | Out-Verbose -Caller Copy-LibraryItem
    $libraryItemService = Get-CisService com.vmware.content.library.item -Verbose:$false
  }

  process {

    # Get destination Content Library object
    $dstLib = $null
    switch ($Destination.GetType().Name) {
      "Library" {$dstLib = $Destination}
      "String"         {$dstLib = Get-Library -Name $Destination}
      default          {throw New-Object System.ArgumentException `
                         "Unsupported library object: $($Destination.GetType().Name)"
                       }
    }
    if (!$dstLib) {
      throw New-Object System.ArgumentException `
        "Destination library '$($Destination.ToString())' not found."
    }
    "Destination: $($dstLib.Name)" | Out-Verbose -Caller Copy-LibraryItem -Verbosity Medium

    foreach ($src in $Source) {

      # Get source Content Library object
      $srcLib   = $null
      switch ($src.GetType().Name) {
        "Library" {$srcLib = $src}
        "String"         {$srcLib = Get-Library -Name $src}
        default          {throw New-Object System.ArgumentException `
                           "Unsupported library object: $($src.GetType().Name)"
                         }
      }
      if (!$srcLib) {
        if ($Ignore) {
          "Source library '$($src.ToString())' not found." | Out-Verbose -Caller Copy-LibraryItem -Verbosity Medium
          continue
        } else {
          throw New-Object System.ArgumentException `
            "Source library '$($src.ToString())' not found."
        }
      }
      "Source:      $($dst.Name)" | Out-Verbose -Caller Copy-LibraryItem -Verbosity Medium

      # Process items from source
      $srcItems = $null
      $srcItems = $srcLib | Get-LibraryItem -Item $Item -Regex:$Regex
      if (!$srcItems) {
        if ($Ignore) {
          "    Library has no items" | Out-Verbose -Caller Copy-LibraryItem -Verbosity Medium
          continue
        } else {
          throw New-Object System.ArgumentException `
            "Source library '$($src.ToString())' has no items."
        }
      }

      foreach ($srcItem in $srcItems) {
        # Check to see if file already exists in destination Content Library
        $result = $null
        $result = $dstLib | Get-LibraryItem -Item $srcItem.Name
        if ($result) {
          if ($Force) {
            # Delete destination file if set to true
            if ($PSCmdlet.ShouldProcess($result.Name)) {
              "    Deleting destination: $($srcItem.Name)" | Out-Verbose -Caller Copy-LibraryItem -Verbosity Medium
              $result | Remove-LibraryItem
            }
          } else {
            "    Item already exists: $($srcItem.Name)" | Out-Verbose -Caller Copy-LibraryItem -Verbosity Medium
            continue
          }
        }

        # Create CopySpec
        $copySpec = $contentLibraryItemService.Help.copy.destination_create_spec.Create()
        $copySpec.library_id = $dstLib.Id
        $copySpec.name = $srcItem.Name
        $copySpec.description = $srcItem.Description
        # Create random Unique Copy Id
        $UniqueChangeId = [guid]::NewGuid().tostring()

        # Perform Copy
        if ($PSCmdlet.ShouldProcess($srcItem.Name)) {
          "    Copying $($srcItem.Name)" | Out-Verbose -Caller Copy-LibraryItem -Verbosity Medium
          try {
            $copyResult = $libraryItemService.copy($UniqueChangeId,
                                                         $srcItem.Id,
                                                         $copySpec)
          } catch {
            Write-Error "Failed to copy: $($srcItem.Name)"
            $Error[0]
            break
          }
        }

        # Delete source file if set to true
        if($Move) {
          if ($PSCmdlet.ShouldProcess($srcItem.Name)) {
            "    Deleting source: $($srcItem.Name)" | Out-Verbose -Caller Copy-LibraryItem -Verbosity Medium
            $srcItem | Remove-LibraryItem
          }
        }
      }
    }
  }

  end {
    "Finished execution" | Out-Verbose -Caller Copy-LibraryItem
  }
}

<#
.SYNOPSIS
  Creates an empty Content Library item
.DESCRIPTION
  This function creates a new, empty, item in the specified vSphere Content Library, with
  the given name.
.NOTES
  Author: Paul Knight (paul.knight@state.de.us)
.PARAMETER Library
.PARAMETER Name
.PARAMETER Description
  An optional string that will be added to the item to describe it.
.EXAMPLE
  New-LibraryItem -Library foo -Name bar
#>
function New-LibraryItem {
  [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="Medium")]
  param (
    [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
    [PSObject]$Library,
    [Parameter(Position=1,Mandatory=$true)]
    [String]$Name,
    [Parameter(Position=2)]
    [String]$Description
  )

  begin {
    "Started execution" | Out-Verbose -Caller New-LibraryItem
    $libraryItemService = Get-CisService com.vmware.content.library.item -Verbose:$false
  }

  process {

    # Get library object
    $libObj  = $null
    switch ($Library.GetType().Name) {
      "Library" {$libObj = $Library}
      "String"         {$libObj = Get-Library -Name $Library}
      default          {throw New-Object System.ArgumentException `
                         "Unsupported object: $($Library.GetType().Name)"
                       }
    }
    if (!$libObj) {
      throw New-Object System.ArgumentException "Library '$($Library.ToString())' not found."
    }
    "Library: $($libObj.Name)" | Out-Verbose -Caller New-LibraryItem -Verbosity Medium

    # Create CopySpec
    $createSpec = $libraryItemService.Help.create.create_spec.Create()
    $createSpec.library_id = $libObj.Id
    $createSpec.name = $Name
    $createSpec.description = $Description
    # Create random Unique Copy Id
    $UniqueChangeId = [guid]::NewGuid().tostring()

    # Perform Copy
    if ($PSCmdlet.ShouldProcess($Name)) {
      try {
        "Creating $Name" | Out-Verbose -Caller New-LibraryItem -Verbosity Medium
        $createResult = $libraryItemService.create($UniqueChangeId, $createSpec)
      } catch {
        Write-Error "Failed to create: $Name"
        $Error[0]
        break
      }
    }
  }

  end {
    "Finished execution" | Out-Verbose -Caller New-LibraryItem
  }
}

<#
.SYNOPSIS
  Deletes items from a Content Library
.DESCRIPTION
  This function deletes specified items from a vSphere Content Library. Items can be
  identified with a wildcard string, or as the output of another Library function.
.NOTES
  Author: Paul Knight (paul.knight@state.de.us)
.PARAMETER Item
  The items to be deleted, specified either as a single wildcard string for the name, or
  one or more Content Library Item objects, which can be piped in.
.PARAMETER Library
  If using a wildcard string for the items to delete, you must specify the vSphere Content
  Library. It can be either by name or object, but it must be a single library.
.PARAMETER Regex
  Use a case-sensitive regular expression instead of wildcards for identifying items.
.EXAMPLE
  Remove-LibraryItem -Library foo -Item "*.iso"

  Removes all iso items from library foo
.EXAMPLE
  Get-LibraryItem -Library foo -Item "*.iso" | Remove-LibraryItem

  Same example using a pipeline instead
#>
function Remove-LibraryItem {
  [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="High")]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='Id')]
    [String]$Id,
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='Name')]
    [PSObject]$Item,
    [Parameter(ParameterSetName='Name')]
    [PSObject]$Library,
    [Parameter(ParameterSetName='Name')]
    [Switch]$Regex
  )

  begin {
    "Started execution" | Out-Verbose -Caller Remove-LibraryItem
    $libraryItemService = Get-CisService com.vmware.content.library.item -Verbose:$false

    # Get optional library objectP
    $libObj  = $null
    if ($Library) {
      switch ($Library.GetType().Name) {
        "Library" {$libObj = $Library}
        "String"         {$libObj = Get-Library -Name $Library}
        default          {throw New-Object System.ArgumentException `
                           "Unsupported object: $($Library.GetType().Name)"
                         }
      }
      "Library: $($libObj.Name)" | Out-Verbose -Caller Remove-LibraryItem -Verbosity Medium
    }
  }

  process {
    if ($Id) {
      if ($PSCmdlet.ShouldProcess($Id)) {
        try {
          "Deleting: $($Id)" | Out-Verbose -Caller Remove-LibraryItem -Verbosity Medium
          $result = $libraryItemService.delete($Id)
        } catch {
          Write-Error "Failed to delete source: $($Id)"
          $Error[0]
          break
        }
      }
    } else {
      # Get Item object list
      $itemObjs= $null
      switch ($Item.GetType().Name) {
        "LibraryItem"  {$itemObjs = $Item}
        "String"  {
                    if ($libObj) {
                      $itemObjs = $libObj | Get-LibraryItem -Item $Item -Regex:$Regex
                    } else {
                      throw New-Object System.ArgumentException `
                        "Library '$($lib.ToString())' not found."
                    }
                  }
        default   {throw New-Object System.ArgumentException `
                    "Unsupported library object: $($Library.GetType().Name)"
                  }
      }

      # Remove each item in list
      foreach ($obj in $itemObjs) {
        if ($PSCmdlet.ShouldProcess($obj.Name)) {
          try {
            "Deleting: $($obj.Name)" | Out-Verbose -Caller Remove-LibraryItem -Verbosity Medium
            $result = $libraryItemService.delete($obj.Id)
          } catch {
            Write-Error "Failed to delete source: $($obj.Name)"
            $Error[0]
            break
          }
        }
      }
    }
  }

  end {
    "Finished execution" | Out-Verbose -Caller Remove-LibraryItem
  }
}


#
# Update Session Utility Cmdlets
#

<#
.SYNOPSIS
  Retrieves update sessions for items in Content Libraries
.DESCRIPTION
  This function retrieves update sessions for the specified item or items from the specified
  library. If none are specified, then all update sessions are retrieved.
.NOTES
  Author: Paul Knight (paul.knight@state.de.us)
.PARAMETER Item
  The items to be checked for update sessions, specified either as a single wildcard string for
  the name, or one or more Content Library Item objects, which can be piped in.
.PARAMETER Library
  If using a wildcard string for the items to delete, you must specify the vSphere Content
  Library. It can be either by name or object, but it must be a single library.
.PARAMETER Regex
  Use a case-sensitive regular expression instead of wildcards for identifying items.
.EXAMPLE
  Get-LibraryUpdateSession -Library foo -Item "*.iso"

  Checks for update session on all iso items from library foo
#>
function Get-LibraryUpdateSession {
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline=$true)]
    [PSObject]$Item,
    [PSObject]$Library,
    [Switch]$Regex
  )

  begin {
    "Started execution" | Out-Verbose -Caller Get-LibraryUpdateSession
    $libraryItemUpdateSessionService = Get-CisService com.vmware.content.library.item.update_session -Verbose:$false

    # Get optional library object
    $libObj  = $null
    if ($Library) {
      switch ($Library.GetType().Name) {
        "Library" {$libObj = $Library}
        "String"  {$libObj = Get-Library -Name $Library}
        default   {throw New-Object System.ArgumentException `
                    "Unsupported object: $($Library.GetType().Name)"
                  }
      }
      "Library: $($libObj.Name)" | Out-Verbose -Caller Get-LibraryUpdateSession -Verbosity Medium
    }
  }

  process {

    # Get Item object list
    $itemObjs= $null
    if ($Item) {
      switch ($Item.GetType().Name) {
        "LibraryItem"  {$itemObjs = $Item}
        "String"  {
                    if ($libObj) {
                      $itemObjs = $libObj | Get-LibraryItem -Item $Item -Regex:$Regex
                    } else {
                      throw New-Object System.ArgumentException `
                        "Library '$($lib.ToString())' not found."
                    }
                  }
        default   {throw New-Object System.ArgumentException `
                    "Unsupported library item object: $($Item.GetType().Name)"
                  }
      }

      # Retrieve update sessions
      foreach ($obj in $itemObjs) {
        $sessionID = $libraryItemUpdateSessionService.list($obj.Id)
        if ($sessionID) {
          $session = $libraryItemUpdateSessionService.get($sessionID.Value)
          [LibraryUpdateSession]::new($obj,$session)
        }
      }
    } else {
      $SessionIDs = $libraryItemUpdateSessionService.list()
      foreach ($sessionID in $sessionIDs) {
        $session = $libraryItemUpdateSessionService.get($sessionID)
        $obj = Get-LibraryItem -Id $session.library_item_id
        [LibraryUpdateSession]::new($obj,$session)
      }
    }
  }

  end {
    "Finished execution" | Out-Verbose -Caller Get-LibraryUpdateSession
  }
}

<#
.SYNOPSIS
  Creates a new update session 
.DESCRIPTION
  This function creates an update session on a specified vSphere Content Library item. An update
  session is used to make modifications to a library item. Modifications are not visible to
  other clients unless the session is completed and all necessary files have been received.
  Content Library Service allows only one single update session to be active for a specific
  library item. The update session will expire by default after 5 minutes unless a keepalive is
  sent.
.NOTES
  Author: Paul Knight (paul.knight@state.de.us)
.PARAMETER Item
  The items to be updated, specified either as a single wildcard string for the name, or one or
  more Content Library Item objects, which can be piped in.
.PARAMETER Library
  If using a wildcard string for the items to update, you must specify the vSphere Content
  Library. It can be either by name or object, but it must be a single library.
.PARAMETER Regex
  Use a case-sensitive regular expression instead of wildcards for identifying items.
.EXAMPLE
  Start-LibraryUpdateSession -Library foo -Item "bar.iso"

  Starts an update session on item named bar.iso from library foo
#>
function New-LibraryUpdateSession {
  [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="Low")]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [PSObject]$Item,
    [PSObject]$Library,
    [Switch]$Regex
  )

  begin {
    "Started execution" | Out-Verbose -Caller New-LibraryUpdateSession
    $libraryItemUpdateSessionService = Get-CisService com.vmware.content.library.item.update_session -Verbose:$false

    # Get optional library object
    $libObj  = $null
    if ($Library) {
      switch ($Library.GetType().Name) {
        "Library" {$libObj = $Library}
        "String"         {$libObj = Get-Library -Name $Library}
        default          {throw New-Object System.ArgumentException `
                           "Unsupported object: $($Library.GetType().Name)"
                         }
      }
    }
  }

  process {

    # Get Item object list
    $itemObjs= $null
    switch ($Item.GetType().Name) {
      "LibraryItem"  {$itemObjs = $Item}
      "String"  {
                  if ($libObj) {
                    $itemObjs = $libObj | Get-LibraryItem -Item $Item -Regex:$Regex
                  } else {
                    throw New-Object System.ArgumentException `
                      "Library '$($lib.ToString())' not found."
                  }
                }
      default   {throw New-Object System.ArgumentException `
                  "Unsupported library object: $($Library.GetType().Name)"
                }
    }

    # Create update sessions
    foreach ($obj in $itemObjs) {

      # Create create spec
      $createSpec = $libraryItemUpdateSessionService.Help.create.create_spec.Create()
      $createSpec.library_item_id = $obj.Id
      $createSpec.library_item_content_version = $obj.ContentVersion
      # Create random Unique Copy Id
      $UniqueChangeId = [guid]::NewGuid().tostring()

      try {
        "Creating update session for $($obj.Name)" | Out-Verbose -Caller New-LibraryUpdateSession -Verbosity Medium
        $sessionID = $libraryItemUpdateSessionService.create($UniqueChangeId, $createSpec)
      } catch {
        Write-Error "Failed to create update session for: $($obj.Name)"
        $Error[0]
        break
      }
      "Session created: $($sessionID.Value)" | Out-Verbose -Caller New-LibraryUpdateSession -Verbosity Medium
      $session = $libraryItemUpdateSessionService.get($sessionID.Value)
      [LibraryUpdateSession]::new($obj,$session)
    }
  }

  end {
    "Finished execution" | Out-Verbose -Caller New-LibraryUpdateSession
  }
}

<#
.SYNOPSIS
  Adds a file to an item
.DESCRIPTION
  This function adds a file to a content library item by attaching the appropriate file spec to
  the provided update session.
.NOTES
  Author: Paul Knight (paul.knight@state.de.us)
.PARAMETER Item
  The LibraryItem object to be updated.
.PARAMETER Uri
  The file to be added. Supported protocols are "http", "https", "file" and, for files on datastores,
  "ds".
.PARAMETER Push
.PARAMETER Pull
.EXAMPLE
  $session | Add-LibraryItemFile -Uri "http://some.com/path/to/file.iso"

  Will pull the file from the specified website.
.EXAMPLE
  $session | Add-LibraryItemFile -Uri "https://some.com/path/to/file.iso"

  Will pull the file from the secured website.
.EXAMPLE
  $session | Add-LibraryItemFile -Uri "file:///some/path/to/file.iso"
.EXAMPLE
  $session | Add-LibraryItemFile -Uri "file:///C:/some/path/to/file.iso"
.EXAMPLE
  $session | Add-LibraryItemFile -Uri "file://unc-server/some/path/to/file.iso"
.EXAMPLE
  $session | Add-LibraryItemFile -Uri "/some/path/to/file.iso"

  Is interpreted as a FILE protocol, and will push the file up.
#>
function Add-LibraryItemFile {
  [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="Low")]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='Default')]
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='Push')]
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='Pull')]
    [LibraryItem]$Item,
    [Parameter(Mandatory=$true,ParameterSetName='Default')]
    [Parameter(Mandatory=$true,ParameterSetName='Push')]
    [Parameter(Mandatory=$true,ParameterSetName='Pull')]
    [String]$Uri,
    [Parameter(Mandatory=$true,ParameterSetName='Push')]
    [Switch]$Push,
    [Parameter(Mandatory=$true,ParameterSetName='Pull')]
    [Switch]$Pull
  )

  begin {
    "Started execution" | Out-Verbose -Caller Add-LibraryItemFile
    $libraryItemUpdateSessionFileService = Get-CisService com.vmware.content.library.item.updatesession.file -Verbose:$false

    $fileName = Split-Path $Uri -leaf
    $fileExt  = [System.IO.Path]::GetExtension($Uri).split('.')[1].ToUpper()

    # Determine protocol
    $uriParts = $Uri.split(':')
    if ($uriParts.Count -gt 1) {
      $Protocol = $uriParts[0].ToUpper()
    } else {
      $Protocol = "FILE"
    }

    # Determine source type and override if specified
    if ($Push) {
      $srcType = "PUSH"
    } elseif ($Pull) {
      $srcType = "PULL"
    } else {
      $srcType = switch ($Protocol) {
        "DS"    {"PUSH"}
        "FILE"  {"PUSH"}
        "HTTP"  {"PULL"}
        "HTTPS" {"PULL"}
        default {
                  throw New-Object System.ArgumentException "Unsupported protocol: $Protocol"
                }
      }
    }
  }

  process {

    # Create session
    $Session = $Item | New-LibraryUpdateSession

    # Create file_spec
    $fileSpec = $libraryItemUpdateSessionFileService.Help.add.file_spec.Create()
    $fileSpec.source_type = $srcType
    $fileSpec.name = $fileName

    if ($srcType -eq "PULL") {
      # Create transfer endpoint
      $srcEndpoint = $libraryItemUpdateSessionFileService.Help.add.file_spec.source_endpoint.Create()
      $srcEndpoint.uri = $Uri
      $fileSpec.source_endpoint = $srcEndpoint
    }

    try {
      $fileInfo = $libraryItemUpdateSessionFileService.add($Session.Id,$fileSpec)
    } catch {
      $Session.ServerError = $_.Exception.ServerError
      throw
    }
    
    if (($Protocol -eq "FILE") -and ($srcType -eq "PUSH")) {
      $UriObj = $fileInfo.upload_endpoint.uri
      $Session | Send-LibraryItemFile -Uri $UriObj -File $Uri
    }
  }

  end {
    "Finished execution" | Out-Verbose -Caller Add-LibraryItemFile
  }
}

function Send-LibraryItemFile {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [LibraryUpdateSession]$Session,
    [Parameter(Mandatory=$true)]
    [PSObject]$Uri,
    [Parameter(Mandatory=$true)]
    [String]$File
  )

  begin {
    "Starting execution" | Out-Verbose -Caller Send-LibraryItemFile

    $webClient = New-Object System.Net.WebClient

    "Registering UploadFileCompleted" | Out-Verbose -Caller Send-LibraryItemFile -Verbosity Medium
    $Global:UploadComplete = $false
    $eventDataComplete = Register-ObjectEvent $webClient UploadFileCompleted `
      -SourceIdentifier WebClient.UploadFileCompleted `
      -Action { $Global:UploadComplete = $true }
    $eventDataComplete | Out-Verbose -Caller Send-LibraryItemFile -Verbosity High

    "Registering UploadProgressChanged" | Out-Verbose -Caller Send-LibraryItemFile -Verbosity Medium
    $Global:UPCEventArgs = $null
    $eventDataProgress = Register-ObjectEvent $webClient UploadProgressChanged `
      -SourceIdentifier WebClient.UploadProgressChanged `
      -Action { $Global:UPCEventArgs = $EventArgs }
    $eventDataProgress | Out-Verbose -Caller Send-LibraryItemFile -Verbosity High
  }

  process {
    # Initiate upload
    $webClient.UploadFileAsync($Uri, "POST", $File)

    # Wait for upload to complete
    Write-Progress -Activity "Uploading file" -Status $File -PercentComplete 0
    while (!($Global:UploadComplete)) {
      $ProgressPercentage = $Global:UPCEventArgs.ProgressPercentage
      if ($ProgressPercentage) {
        Write-Progress -Activity "Uploading file" -Status $File -PercentComplete $ProgressPercentage
        if ($Session.Progress -ne $ProgressPercentage) {
          ("{0}%" -f $ProgressPercentage) | Out-Verbose -Caller Send-LibraryItemFile -Verbosity High
        }
      }
      $Session.KeepAlive($ProgressPercentage)
      Sleep 1
    }
  }

  end {
    Unregister-Event -SourceIdentifier WebClient.UploadProgressChanged
    Unregister-Event -SourceIdentifier WebClient.UploadFileCompleted
    $webClient.Dispose()

    if ($Global:UploadComplete) {
      "Upload complete." | Out-Verbose -Caller Send-LibraryItemFile -Verbosity Medium
      $Session.Complete()
    } else {
      "Upload not completed. How did I get here?" | Out-Verbose -Caller Send-LibraryItemFile -Verbosity Medium
    }
    $Global:UploadComplete = $null
    $Global:UPCEventArgs = $null
    Remove-Variable webClient
    Remove-Variable eventDataComplete
    Remove-Variable eventDataProgress
    [GC]::Collect()
    "Finished execution" | Out-Verbose -Caller Send-LibraryItemFile
  }
}

<#
.SYNOPSIS
  Removes a file from an item
.DESCRIPTION
  This function removes a file from a content library item by attaching the appropriate file spec to
  the provided update session.
.NOTES
  Author: Paul Knight (paul.knight@state.de.us)
.PARAMETER Session
  The LibraryUpdateSession object describing the session to be updated.
.PARAMETER Name
  The name of the file to be removed. 
.EXAMPLE
  $session | Remove-LibraryItemFile -Name "file.iso"

  Will remove file.iso from the specified website.
#>
function Remove-LibraryItemFile {
  [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="High")]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [PSObject]$Item,
    [PSObject]$Library,
    [String]$Name = "*",
    [Switch]$Regex
  )

  begin {
    "Starting execution" | Out-Verbose -Caller Remove-LibraryItemFile
    $libraryItemUpdateSessionService = Get-CisService com.vmware.content.library.item.update_session -Verbose:$false
    $libraryItemUpdateSessionFileService = Get-CisService com.vmware.content.library.item.updatesession.file -Verbose:$false

    # Get optional library object
    $libObj  = $null
    if ($Library) {
      switch ($Library.GetType().Name) {
        "Library" {$libObj = $Library}
        "String"  {$libObj = Get-Library -Name $Library}
        default   {throw New-Object System.ArgumentException `
                    "Unsupported object: $($Library.GetType().Name)"
                  }
      }
      "Library: $($libObj.Name)" | Out-Verbose -Caller Remove-LibraryItemFile -Verbosity Medium
    }
  }

  process {

    $itemObjs = $null
    switch ($Item.GetType().Name) {
      "LibraryItem"  {$itemObjs = $Item}
      "String"  {
                  if ($libObj) {
                    $itemObjs = $libObj | Get-LibraryItem -Item $Item -Regex:$Regex
                  } else {
                    throw New-Object System.ArgumentException `
                      "Library '$($lib.ToString())' not found."
                  }
                }
      default   {throw New-Object System.ArgumentException `
                  "Unsupported library object: $($Library.GetType().Name)"
                }
    }

    foreach ($obj in $itemObjs) {
      "Item: $($obj.Name)" | Out-Verbose -Caller Remove-LibraryItemFile -Verbosity Medium
      foreach ($file in $obj.Files) {
        if ((!$Regex -and ($file.Name -like $Name)) -or
            ($Regex -and ($file.Name -cmatch $Name))) {
          if ($PSCmdlet.ShouldProcess($file.Name)) {
            $Session = $obj | New-LibraryUpdateSession
            if ($Session) {
              "File: $($file.Name)" | Out-Verbose -Caller Remove-LibraryItemFile -Verbosity Medium
              $fileInfo = $libraryItemUpdateSessionFileService.remove($Session.Id,$file.Name)
              $Session.Complete()
            }
          }
        }
      }
    }
  }

  end {
    "Finished execution" | Out-Verbose -Caller Remove-LibraryItemFile
  }
}


#
# Initialize Module
#
#. Initialize-Module
Export-ModuleMember Add-LibraryItemFile
Export-ModuleMember Copy-LibraryItem
Export-ModuleMember Get-Library
Export-ModuleMember Get-LibraryItem
Export-ModuleMember Get-LibraryUpdateSession
Export-ModuleMember New-LibraryItem
Export-ModuleMember New-LibraryUpdateSession
Export-ModuleMember New-LocalLibrary
Export-ModuleMember New-SubscribedLibrary
Export-ModuleMember Remove-LibraryItem
Export-ModuleMember Remove-LibraryItemFile
Export-ModuleMember Remove-LocalLibrary
Export-ModuleMember Remove-SubscribedLibrary
Export-ModuleMember Send-LibraryItemFile
Export-ModuleMember Set-Library
