import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';

import { Platform } from '@ionic/angular';
import { SplashScreen } from '@ionic-native/splash-screen/ngx';
import { StatusBar } from '@ionic-native/status-bar/ngx';
import { Plugins } from "@capacitor/core"

const { CustomPlugin, Geolocation } = Plugins
@Component({
  selector: 'app-root',
  templateUrl: 'app.component.html',
  styleUrls: ['app.component.scss']
})
export class AppComponent implements OnInit, OnDestroy {

  text: string = ''
  inputText = ''

  constructor(
    private platform: Platform,
    private splashScreen: SplashScreen,
    private statusBar: StatusBar,
    private cdRef: ChangeDetectorRef,
  ) {
    this.initializeApp()
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
    this.myPluginEventListener = CustomPlugin.addListener('myPluginEvent', (info: any) => {
      this.showValue(info)
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
}
