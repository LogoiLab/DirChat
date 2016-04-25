function New-DirectoryProperty{
  param(
    [Parameter(Mandatory=$True)]
      [string]$Path,
    [Parameter(Mandatory=$False)]
      [string]$Header,
    [Parameter(Mandatory=$True)]
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
    Throw "$Data cannot be null."
  }
  if($Force -eq $true){
    #header.data.footer
    if($Header -ne $null -and $Footer -ne $null){
      New-Item -Path $Path -Name "$Header.$Data.$Footer" -ItemType Directory -Force
      Return (Convert-Path -Path "$Path\$Header.$Data.$Footer")
    }
    #header.data
    elseif($Header -ne $null -and $Footer -eq $null){
      New-Item -Path $Path -Name "$Header.$Data." -ItemType Directory -Force
      Return (Convert-Path -Path "$Path\$Header.$Data.")
    }
    #header.data
    elseif($Header -eq $null -and $Footer -ne $null){
      New-Item -Path $Path -Name "$Data.$Footer" -ItemType Directory -Force
      Return (Convert-Path -Path "$Path\$Data.$Footer")
    }
    #data
    elseif($Header -eq $null -and $Footer -eq $null){
      New-Item -Path $Path -Name ".$Data." -ItemType Directory -Force
      Return (Convert-Path -Path "$Path\.$Data.")
    }
  }
  else{
    if($Header -ne $null -and $Footer -ne $null){
      New-Item -Path $Path -Name "$Header.$Data.$Footer" -ItemType Directory
      Return (Convert-Path -Path "$Path\$Header.$Data.$Footer")
    }
    elseif($Header -ne $null -and $Footer -eq $null){
      New-Item -Path $Path -Name "$Header.$Data." -ItemType Directory
      Return (Convert-Path -Path "$Path\$Header.$Data.")
    }
    elseif($Header -eq $null -and $Footer -ne $null){
      New-Item -Path $Path -Name ".$Data.$Footer" -ItemType Directory
      Return (Convert-Path -Path "$Path\.$Data.$Footer")
    }
    elseif($Header -eq $null -and $Footer -eq $null){
      New-Item -Path $Path -Name ".$Data." -ItemType Directory
      Return (Convert-Path -Path "$Path\.$Data.")
    }
  }
  Return $false
}
