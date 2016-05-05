function Remove-DirectoryProperty{
  param(
    [Parameter(Mandatory=$True)]
      [string]$Path,
    [Parameter(Mandatory=$False)]
      [string]$OldHeader,
    [Parameter(Mandatory=$True)]
      [string]$OldData,
    [Parameter(Mandatory=$False)]
      [string]$OldFooter,
    [Parameter(Mandatory=$False)]
      [switch]$Header,
    [Parameter(Mandatory=$False)]
      [switch]$Footer,
    [Parameter(Mandatory=$False)]
      [switch]$Force
  )
  if($Header -and $Footer){
    Rename-Item -Path "$Path\$OldHeader.$OldData.$OldFooter" -Name ".$OldData." -Force $Force
    Return (Convert-Path -Path "$Path\.$OldData.")
  }
  elseif($Header){
    Rename-Item -Path "$Path\$OldHeader.$OldData.$OldFooter" -Name ".$OldData.$OldFooter" -Force $Force
    Return (Convert-Path -Path "$Path\$Header.$Data")
  }
  elseif($Footer){
    Rename-Item -Path "$Path\$OldHeader.$OldData.$OldFooter" -Name "$OldHeader.$OldData." -Force $Force
    Return (Convert-Path -Path "$Path\$Data.$Footer")
  }
}
