function Show-CloseRoom{
  $xaml = Get-Content "\XAML\RoomCloseWindow.xaml"
  #Load XAML
  $reader=(New-Object System.Xml.XmlNodeReader $xaml)
  $Window=[Windows.Markup.XamlReader]::Load($reader)
  $Window.showDialog()
}
