function Show-JoinRoom{
  $xaml = Get-Content "\XAML\RoomJoinWindow.xaml"
  #Load XAML
  $reader=(New-Object System.Xml.XmlNodeReader $xaml)
  $Window=[Windows.Markup.XamlReader]::Load($reader)
  $Window.showDialog()
}
