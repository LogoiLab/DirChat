function Start-DirChat{
  param(
    [switch]$Splash
  )
  if($Splash){
    $Spxaml = Get-Content ".\Windows\SplashWindow.xaml"
    #Load XAML
    $SpReader=(New-Object System.Xml.XmlNodeReader $xaml)
    $SplashWindow=[Windows.Markup.XamlReader]::Load($reader)
  }
  $xaml = Get-Content ".\Windows\MainWindow.xaml"
  #Load XAML
  $reader=(New-Object System.Xml.XmlNodeReader $xaml)
  $Window=[Windows.Markup.XamlReader]::Load($reader)

  ##Controls
  $Script:Paragraph = $Window.FindName('Paragraph')
  $Script:OnlineUsers = $Window.FindName('OnlineUsers')
  $Script:Send = $Window.FindName('Send')
  $Script:UserList = $Window.FindName('UserPanel')
  $Script:ClubbList = $Window.FindName('ClubbPanel')
  $Script:RoomList = $Window.FindName('RoomPanel')
  $Script:MainMessage = $Window.FindName('MainMessage_txt')
  $Script:ExitMenu = $Window.FindName('ExitMenu')
  $Script:SaveTranscript = $Window.FindName('SaveTranscript')
  $Script:AboutMenu = $Window.FindName('AboutMenu')

  ##Events

  #ExitMenu
  $ExitMenu.Add_Click({
      $Window.Close()
  })

  #AboutMenu
  $AboutMenu.Add_Click({
      Show-About
  })

  #Connect
  $ConnectButton.Add_Click({})

  #Send message
  $SendButton.Add_Click({
      #Send message to server
      If (($Inputbox_txt.Text).StartsWith("@")) {
          $Messagequeue.Enqueue(("~I{0}{1}{2}" -f $username,"~~",$Inputbox_txt.Text))
      }
      $Message = "~M{0}{1}{2}" -f $username,"~~",$Inputbox_txt.Text
      $data = [text.Encoding]::Ascii.GetBytes($Message)
      $ServerStream.Write($data,0,$data.length)
      $ServerStream.Flush()
      $Inputbox_txt.Clear()
  })

  #Load Window
  $Window.Add_Loaded({
      #Dictionary of colors for Fonts
      $script:colors = @{}
      $Color = [windows.media.colors] | Get-Member -static -Type Property | Select -Expand Name | ForEach {
          $colors["$([windows.media.colors]::$_)"] = $_
          $colors[$_] = "$([windows.media.colors]::$_)"
      }
      #Date placeholder for later use
      $Global:Date = Get-Date -Format ddMMyyyy
      #Used for managing the queue of messages in an orderly fashion
      $Global:MessageQueue =  [System.Collections.Queue]::Synchronized((New-Object System.collections.queue))
      #Used for managing client connection
      $Global:ClientConnection = [hashtable]::Synchronized(@{})
      #Create Timer object
      $Global:timer = New-Object System.Windows.Threading.DispatcherTimer
      #Fire off every 1 seconds
      $timer.Interval = [TimeSpan]"0:0:1.00"
      #Add event per tick
      $timer.Add_Tick({
          [Windows.Input.InputEventHandler]{ $Global:Window.UpdateLayout() }
          If ($Messagequeue.Count -gt 0) {
              $Message = $Messagequeue.Dequeue()
              #If a different day then when client started
              If ($date -ne (Get-Date -Format ddMMyyyy)) {
                  $date = (Get-Date -Format ddMMyyyy)
                  $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0} " -f (Get-Date).ToShortDateString()) -ForeGround Black -Bold))
                  $Paragraph.Inlines.Add((New-Object System.Windows.Documents.LineBreak))
              }
              Switch ($Message) {
                  {$_.Startswith("~B")} {
                      #Message
                      $data = ($_).SubString(2)
                      $split = $data -split ("{0}" -f "~~")
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("[{0}] " -f (Get-Date).ToLongTimeString()) -ForeGround Gray))
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}: " -f $split[0]) -ForeGround Black -Bold))
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}" -f $split[1]) -ForeGround Orange))
                  }
                  {$_.Startswith("~I")} {
                      #Message
                      $data = ($_).SubString(2)
                      $split = $data -split ("{0}" -f "~~")
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("[{0}] " -f (Get-Date).ToLongTimeString()) -ForeGround Gray))
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}: " -f $split[0]) -ForeGround Black -Bold))
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}" -f $split[1]) -ForeGround Blue))
                  }
                  {$_.Startswith("~M")} {
                      #Message
                      $data = ($_).SubString(2)
                      $split = $data -split ("{0}" -f "~~")
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("[{0}] " -f (Get-Date).ToLongTimeString()) -ForeGround Gray))
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}: " -f $split[0]) -ForeGround Black -Bold))
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0}" -f $split[1]) -ForeGround Black))
                  }
                  {$_.Startswith("~D")} {
                      #Disconnect
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("[{0}] " -f (Get-Date).ToLongTimeString()) -ForeGround Gray))
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("{0} has disconnected from the server" -f $_.SubString(2)) -ForeGround Green))
                      #Remove user from online list
                      $OnlineUsers.Items.Remove($_.SubString(2))
                  }
                  {$_.StartsWith("~C")} {
                      #Connect
                      $Message = ("{0} has connected to the server" -f $_.SubString(2))
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("[{0}] " -f (Get-Date).ToLongTimeString()) -ForeGround Gray))
                      $Paragraph.Inlines.Add((New-ChatMessage -Message $message -ForeGround Green))
                      ##Add user to online list
                      If ($Username -ne $_.SubString(2)) {
                          $OnlineUsers.Items.Add($_.SubString(2))
                      }
                  }
                  {$_.StartsWith("~S")} {
                      #Server Shutdown
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("[{0}] " -f (Get-Date).ToLongTimeString()) -ForeGround Gray))
                      $Paragraph.Inlines.Add((New-ChatMessage -Message ("SERVER HAS DISCONNECTED.") -ForeGround Red))
                      $TcpClient.Close()
                      $ClientConnection.user.PowerShell.EndInvoke($ClientConnections.user.Job)
                      $ClientConnection.user.PowerShell.Runspace.Close()
                      $ClientConnection.user.PowerShell.Dispose()
                      $ConnectButton.IsEnabled = $True
                      $DisconnectButton.IsEnabled = $False
                      $OnlineUsers.Items.Clear()
                  }
                  {$_.StartsWith("~Z")} {
                      #List of connected users
                      $online = (($_).SubString(2) -split "~~")
                      #Add online users to window
                      $Online | ForEach {
                          $OnlineUsers.Items.Add($_)
                      }
                  }
                  Default {
                      $MainMessage.text += ("[{0}] {1}" -f (Get-Date).ToLongTimeString(),$_)
                  }
              }
          $Paragraph.Inlines.Add((New-Object System.Windows.Documents.LineBreak))
          $MainMessage.ScrollToEnd()
          }
      })
      #Start timer
      $timer.Start()
      If (-NOT $timer.IsEnabled) {
          $Window.Close()
      }
  })
  #Close Window
  $Window.Add_Closed({
  })

  #Disconnect from server
  $DisconnectButton.Add_Click({
      $Paragraph.Inlines.Add((New-ChatMessage -Message ("[{0}] " -f (Get-Date).ToLongTimeString()) -ForeGround Gray))
      $Paragraph.Inlines.Add((New-ChatMessage -Message ("Disconnecting from server: {0}" -f $Server) -ForeGround Red))
      $Paragraph.Inlines.Add((New-Object System.Windows.Documents.LineBreak))
      #Shutdown client runspace and socket
      $TcpClient.Close()
      $ClientConnection.user.PowerShell.EndInvoke($ClientConnection.user.Job)
      $ClientConnection.user.PowerShell.Runspace.Close()
      $ClientConnection.user.PowerShell.Dispose()
      $ConnectButton.IsEnabled = $True
      $DisconnectButton.IsEnabled = $False
      $OnlineUsers.Items.Clear()
  })

  $Window.Add_KeyDown({
      $key = $_.Key
      If ([System.Windows.Input.Keyboard]::IsKeyDown("RightCtrl") -OR [System.Windows.Input.Keyboard]::IsKeyDown("LeftCtrl")) {
          Switch ($Key) {
          "E" {$Window.Close()}
          "RETURN" {
              Write-Verbose ("Sending message")
              If (($Inputbox_txt.Text).StartsWith("@")) {
                  $Messagequeue.Enqueue(("~I{0}{1}{2}" -f $username,"~~",$Inputbox_txt.Text))
              }
              $Message = "~M{0}{1}{2}" -f $username,"~~",$Inputbox_txt.Text
              $data = [text.Encoding]::Ascii.GetBytes($Message)
              $ServerStream.Write($data,0,$data.length)
              $ServerStream.Flush()
              $Inputbox_txt.Clear()
          }
          "S" {Save-Transcript}
          Default {$Null}
          }
      }
  })

  [void]$Window.showDialog()

  }).BeginInvoke()
}
