function Set-DirectoryProperty{
  param(
    [Parameter(Mandatory=$True)]
      [string]$Path,
    [Parameter(Mandatory=$False)]
      [string]$OldHeader,
    [Parameter(Mandatory=$False)]
      [string]$OldData,
    [Parameter(Mandatory=$False)]
      [string]$OldFooter,
    [Parameter(Mandatory=$False)]
      [string]$Header,
    [Parameter(Mandatory=$False)]
      [string]$Data,
    [Parameter(Mandatory=$False)]
      [string]$Footer,
    [Parameter(Mandatory=$False)]
      [switch]$Force
  )
  if(
      $Path -eq $null -or
        !(Test-Path -Path $Path -IsValid) -or
        !(Test-Path -Path $Path)
  ){
    Throw "$Path is not a valid path."
  }
  if($Data -eq $null){
    if($Header -ne $null -and $Footer -ne $null){
      Rename-Item -Path "$Path\$OldHeader.$OldData.$OldFooter" -Name "$Header.$OldData.$Footer" -Force $Force
      Return (Convert-Path -Path "$Path\$Header.$Data.$Footer")
    }
    elseif($Header -ne $null -and $Footer -eq $null){
      Rename-Item -Path "$Path\$OldHeader.$OldData.$OldFooter" -Name "$Header.$OldData.$OldFooter" -Force $Force
      Return (Convert-Path -Path "$Path\$Header.$Data")
    }
    elseif($Header -eq $null -and $Footer -ne $null){
      Rename-Item -Path "$Path\$OldHeader.$OldData.$OldFooter" -Name "$OldHeader.$OldData.$Footer" -Force $Force
      Return (Convert-Path -Path "$Path\$Data.$Footer")
    }
    elseif($Header -eq $null -and $Footer -eq $null){
      Rename-Item -Path "$Path\$OldHeader.$OldData.$OldFooter" -Name "$OldHeader.$Data.$OldFooter" -Force $Force
      Return (Convert-Path -Path "$Path\$Data")
    }
  }
  else{
    if($Header -ne $null -and $Footer -ne $null){
      Rename-Item -Path "$Path\$OldHeader.$OldData.$OldFooter" -Name "$Header.$Data.$Footer" -Force $Force
      Return (Convert-Path -Path "$Path\$Header.$Data.$Footer")
    }
    elseif($Header -ne $null -and $Footer -eq $null){
      Rename-Item -Path "$Path\$OldHeader.$OldData.$OldFooter" -Name "$Header.$Data.$OldFooter" -Force $Force
      Return (Convert-Path -Path "$Path\$Header.$Data")
    }
    elseif($Header -eq $null -and $Footer -ne $null){
      Rename-Item -Path "$Path\$OldHeader.$OldData.$OldFooter" -Name "$OldHeader.$Data.$Footer" -Force $Force
      Return (Convert-Path -Path "$Path\$Data.$Footer")
    }
    elseif($Header -eq $null -and $Footer -eq $null){
      Rename-Item -Path "$Path\$OldHeader.$OldData.$OldFooter" -Name "$OldHeader.$Data.$OldFooter" -Force $Force
      Return (Convert-Path -Path "$Path\$Data")
    }
  }
  Return $false
}
