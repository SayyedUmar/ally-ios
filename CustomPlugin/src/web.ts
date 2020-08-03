import { WebPlugin } from '@capacitor/core';
import { CustomPluginPlugin } from './definitions';

export class CustomPluginWeb extends WebPlugin implements CustomPluginPlugin {
  constructor() {
    super({
      name: 'CustomPlugin',
      platforms: ['web'],
    });
  }

  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    let value = options.value
    return {value}
  }
}

const CustomPlugin = new CustomPluginWeb();

export { CustomPlugin };

import { registerWebPlugin } from '@capacitor/core';
registerWebPlugin(CustomPlugin);
