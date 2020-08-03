declare module '@capacitor/core' {
  interface PluginRegistry {
    CustomPlugin: CustomPluginPlugin;
  }
}

export interface CustomPluginPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
