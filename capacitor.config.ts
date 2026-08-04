import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
	appId: 'com.azawy.macosweb',
	appName: 'MacOSWeb',
	webDir: 'dist',

	// The web app already renders its own "desktop", dock, and animations — we don't
	// want Capacitor injecting its own splash/back-button/status-bar behavior on top
	// of that, so most native UI plugins are intentionally left out.
	server: {
		androidScheme: 'https',
	},

	ios: {
		contentInset: 'never',
		backgroundColor: '#000000',
	},
};

export default config;
