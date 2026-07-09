// Minimal ambient WebXR types for the AR code in this project.
//
// The full WebXR type surface is large and `@types/webxr` is deprecated
// (WebXR types ship in modern TS lib.dom.d.ts, but this project's TS setup
// doesn't expose them on Navigator). Rather than vendor hundreds of lines,
// we declare just enough for strict checkJs to pass: `navigator.xr` exists,
// and the session/space/hit-test objects it returns are typed as `any` —
// matching how the AR routes use them (dynamic three.js + raw WebXR).
// No runtime code; declaration file only.

interface XRSessionInit {
	optionalFeatures?: string[];
	domOverlay?: { root: HTMLElement };
	[key: string]: any;
}

interface XRSession {
	requestReferenceSpace(type: string): Promise<any>;
	requestHitTestSource(options: any): Promise<any>;
	end(): Promise<void>;
	addEventListener(type: string, listener: (event: any) => void): void;
	removeEventListener(type: string, listener: (event: any) => void): void;
	updateTargetFrameRate?(rate: number): Promise<void>;
	[key: string]: any;
}

interface XRSystem {
	isSessionSupported(mode: string): Promise<boolean>;
	requestSession(mode: string, options?: XRSessionInit): Promise<XRSession>;
}

interface Navigator {
	readonly xr?: XRSystem;
}
