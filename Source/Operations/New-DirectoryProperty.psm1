function New-DirectoryProperty{
  param(
    [Parameter(Mandatory=$True)]
      [string]$Path,
    [Parameter(Mandatory=$False)]
      [string]$Header,
    [Parameter(Mandatory=$True)]
      [string]$Data,
    [Parameter(Mandatory=$False)]
      [string]$Footer
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
    if($Header -ne $null -and $Footer -eq $null){
      New-Item -Path $Path -Name "$Header.$Data" -ItemType Directory -Force
    }
    elseif($Header -eq $null -and $Footer -ne $null){
      New-Item -Path $Path -Name "$Data.$Footer" -ItemType Directory -Force
    }
    elseif($Header -eq $null -and $Footer -eq $null){
      New-Item -Path $Path -Name "$Data" -ItemType Directory -Force
    }
  }
  else{

  }
  New-Item -Path $Path -Name "$Header.$Data.$Footer" -ItemType Directory -Force
}
