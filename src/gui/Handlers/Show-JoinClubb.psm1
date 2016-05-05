function Show-JoinClubb{
  $xaml = Get-Content "\XAML\ClubbJoinWindow.xaml"
  #Load XAML
  $reader=(New-Object System.Xml.XmlNodeReader $xaml)
  $Window=[Windows.Markup.XamlReader]::Load($reader)
  $Window.showDialog()
}
