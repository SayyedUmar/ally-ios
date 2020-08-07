import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';

import { Platform } from '@ionic/angular';
import { SplashScreen } from '@ionic-native/splash-screen/ngx';
import { StatusBar } from '@ionic-native/status-bar/ngx';
import { Plugins } from "@capacitor/core"
import { AlertController } from '@ionic/angular';

const { CustomPlugin, Geolocation } = Plugins
@Component({
  selector: 'app-root',
  templateUrl: 'app.component.html',
  styleUrls: ['app.component.scss']
})
export class AppComponent implements OnInit, OnDestroy {

  text: string = ''
  inputText = ''
  person_list: Person[] = []
  selectedUser: Person
  ifMonitoringStarted = false
  lat: number
  lng: number
  date: string

  constructor(
    private platform: Platform,
    private splashScreen: SplashScreen,
    private statusBar: StatusBar,
    private cdRef: ChangeDetectorRef,
    public alertController: AlertController
  ) {
    this.initializeApp()
    this.person_list = [
      new Person('Tushar - Kamlesh', 'B08FFE14-1AB0-4321-A46D-98E8FC74AA71', 'bcf7b96dbdefbde1'), //Victim 01 Kamlesh - Customer 1
      new Person('Sapandeep - Abhay', '84C515A8-A00D-4E06-81B4-48592351C096', '9233c89d05d89799'),
      new Person('Brijesh - Brijesh', '4099f9a0-23ba-4ce7-93b8-eabfaf29b259', 'CBC7AB1A-BDCA-4E49-AE19-A61F0BE05610'), //Brijesh Victim
      //new Person('Brijesh - Shruti', 'EC4100E1-098D-41B5-B845-96FEA35C417D', '3250aba86473c6c6'), //Shruti Kulkarni - Customer 1
      //00008030-001549E214F2802E
      // new Person('Abhay', '', ''),
    ]
  }

  async getCurrentPosition() {
    const coordinates = await Geolocation.getCurrentPosition()
    console.log('Current', coordinates);
  }

  watchPosition() {
    const wait = Geolocation.watchPosition({}, (position, err) => {

    })
  }

  initializeApp() {
    this.platform.ready().then(() => {
      this.statusBar.styleDefault();
      this.splashScreen.hide();
    });
  }

  myPluginEventListener
  ngOnInit () {
    console.log('onInit')
    this.myPluginEventListener = CustomPlugin.addListener('onLocationCapture', (info: any) => {
      //this.showValue(info)
      console.log('onLocationCapture', info)
      this.date = info.date
      this.lat = info.lat
      this.lng = info.lng
      this.cdRef.detectChanges();
    })
  }

  showValue(info) {
      this.text = info.value
      console.log('myPluginEvent was fired', this.text);
      this.cdRef.detectChanges();
  }
  

  ngOnDestroy () {
    this.myPluginEventListener.remove();
  }

  onCLick() {
    this.getTimes()
    // console.log(result)
    // this.text = 'Hi There'
  }

  async getTimes() {
    const result = await CustomPlugin.echo({ value:  this.inputText, person: {name: 'Umar Sayyed', age:28}})
    console.log('getTimes', result.value)
    this.text = result.value
  }

  async onStartMonitoringLocation () {
    if (this.selectedUser == null) {
      this.presentAlertConfirm() 
      return
    }
    if (this.ifMonitoringStarted == true) return
    this.text = 'Hi '+this.selectedUser.name+', Welcome to ionic.'
    console.log(this.selectedUser)
    const result = await CustomPlugin.echo({ value:  "onStartMonitoringLocation", person: this.selectedUser})
    console.log('getTimes', result.value)
    this.ifMonitoringStarted = true
  }

  async onStopMonitoringLocation () {
    if (this.ifMonitoringStarted == false) return
    const result = await CustomPlugin.echo({ value:  "onStopMonitoringLocation", person: this.selectedUser})
    console.log('getTimes', result.value)
    this.ifMonitoringStarted = false
  }

  async emailLogFile () {
    const result = await CustomPlugin.echo({ value:  "emailLogFile", person: null})
    console.log('getTimes', result.value)
  }

  async presentAlertConfirm() {
    const alert = await this.alertController.create({
      cssClass: 'my-custom-class',
      header: 'Error',
      message: 'Please select user from list',
      buttons: [
        {
          text: 'Cancel',
          role: 'cancel',
          cssClass: 'secondary',
          handler: (blah) => {
            console.log('Confirm Cancel: blah');
          }
        }, {
          text: 'Okay',
          handler: () => {
            console.log('Confirm Okay');
          }
        }
      ]
    });

    await alert.present();
  }
}


class Person {
  constructor(
    public name: string,
    public victimId: string,
    public deviceId: string,
    ) {

    }
}