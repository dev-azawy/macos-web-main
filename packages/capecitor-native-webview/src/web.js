import { WebPlugin } from '@capacitor/core';

export class NativeWebviewWeb extends WebPlugin {
	async open() {
		// No-op on the web: WebApp.svelte uses an <iframe> fallback instead when
		// running outside of the native iOS shell.
	}
	async update() {}
	async focus() {}
	async close() {}
	async loadUrl() {}
	async goBack() {}
	async goForward() {}
	async reload() {}
}
