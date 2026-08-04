import { registerPlugin } from '@capacitor/core';

const NativeWebview = registerPlugin('NativeWebview', {
	web: () => import('./web.js').then((m) => new m.NativeWebviewWeb()),
});

export { NativeWebview };
