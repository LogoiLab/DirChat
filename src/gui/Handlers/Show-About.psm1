function Show-About{
  $xaml = Get-Content "\XAML\AboutWindow.xaml"
  #Load XAML
  $reader=(New-Object System.Xml.XmlNodeReader $xaml)
  $Window=[Windows.Markup.XamlReader]::Load($reader)
  $Window.showDialog()
}
