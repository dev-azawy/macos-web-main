export interface NativeWebviewFrame {
	id: string;
	x: number;
	y: number;
	width: number;
	height: number;
}

export interface NavigationState {
	id: string;
	url: string;
	title: string;
	canGoBack: boolean;
	canGoForward: boolean;
	loading: boolean;
}

export interface NativeWebviewPlugin {
	open(options: NativeWebviewFrame & { url: string }): Promise<void>;
	update(options: NativeWebviewFrame & { visible?: boolean }): Promise<void>;
	focus(options: { id: string }): Promise<void>;
	close(options: { id: string }): Promise<void>;
	loadUrl(options: { id: string; url: string }): Promise<void>;
	goBack(options: { id: string }): Promise<void>;
	goForward(options: { id: string }): Promise<void>;
	reload(options: { id: string }): Promise<void>;
	addListener(
		eventName: 'navigationStateChanged',
		listenerFunc: (state: NavigationState) => void,
	): Promise<{ remove: () => void }>;
}

export declare const NativeWebview: NativeWebviewPlugin;
