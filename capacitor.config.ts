import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'kr.ai.perfect.reversechess',
  appName: '리버스 체스',
  webDir: 'www',
  ios: {
    contentInset: 'never',
    backgroundColor: '#181310',
  },
};

export default config;
