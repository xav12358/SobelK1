package com.markerdetector;

//import android.support.v7.app.ActionBarActivity;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.List;

import android.graphics.Bitmap;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.os.Handler;

import java.io.IOException;
import java.util.List;


import android.util.Log;
import android.graphics.Bitmap;
import android.graphics.PixelFormat;
import android.graphics.SurfaceTexture;
import android.hardware.Camera;
import android.hardware.Camera.Size;
import android.os.Bundle;
import android.view.TextureView;
import android.widget.ImageView;
import android.widget.TextView;
import android.app.Activity;
import android.opengl.GLSurfaceView;


public class MainActivity extends Activity implements
Camera.PreviewCallback {

	static{
		System.loadLibrary("MarkerDetector");
	}

	private Camera mCamera;
	private byte[] mVideoSource;

	
	private Bitmap mImage;
	private GLSurfaceView SurfaceView;
	private ImageView mImgView;
	private SurfaceTexture surfaceTexture;
	private TextView textView;


	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		setContentView(R.layout.activity_main);
		mImgView 		= ((ImageView)findViewById(R.id.imageView));
		SurfaceView 	= ((GLSurfaceView)findViewById(R.id.imageViewGL));
		textView		= ((TextView)findViewById(R.id.textView));
		
		surfaceTexture 	= new SurfaceTexture(0);
		SurfaceView.setRenderer(new GLES20Renderer());

		startCamera();
	}

//	@Override
//	public boolean onCreateOptionsMenu(Menu menu) {
//		// Inflate the menu; this adds items to the action bar if it is present.
//		getMenuInflater().inflate(R.menu.main, menu);
//		return true;
//	}


	public void startCamera() 
	{
		mCamera = Camera.open();
		
		Log.i("TAG","onSurfaceTextureAvailable\n");

		try {
			
			mCamera.setPreviewTexture(surfaceTexture);
			mCamera.setPreviewCallbackWithBuffer(this);
			
			// Sets landscape mode to avoid complications related to
			// screen orientation handling.
			mCamera.setDisplayOrientation(0);


			// Finds a suitable resolution.
			Size size = mCamera.new Size(640, 480);

			PixelFormat pixelFormat = new PixelFormat();
			PixelFormat.getPixelFormatInfo(mCamera.getParameters()
					.getPreviewFormat(), pixelFormat);
			int sourceSize = size.width * size.height
					* pixelFormat.bitsPerPixel / 8;
			
			// Set-up camera size and video format. YCbCr_420_SP
			// should be the default on Android anyway.
			Camera.Parameters parameters = mCamera.getParameters();
			parameters.setPreviewSize(640, 480);
			parameters.setPreviewFormat(PixelFormat.YCbCr_420_SP);
			mCamera.setParameters(parameters);

			// Prepares video buffer and bitmap buffers.
			mVideoSource = new byte[sourceSize];
			mImage = Bitmap.createBitmap(size.width, size.height,Bitmap.Config.ALPHA_8);
			mImgView.setImageBitmap(mImage);

			Log.i("TAG","onSurfaceTextureAvailable1 "+size.width + size.height + pixelFormat.bitsPerPixel);

			// Starts receiving pictures from the camera.
			mCamera.addCallbackBuffer(mVideoSource);
			mCamera.startPreview();
			
		} catch (IOException ioe) {
			mCamera.release();
			mCamera = null;
			throw new IllegalStateException();
		}
	}



	@Override
	public void onPreviewFrame(byte[] pData, Camera pCamera) {
		// New data has been received from camera. Processes it and
		// requests surface to be redrawn right after.
		
		Log.i("TAG","onPreviewFrame\n");
		if (mCamera != null) {
			Log.i("TAG","onPreviewFrame2\n");
			String returnValue = processMarker(mImage,pData);	
			mImgView.invalidate();

			Log.i("TAG","onPreviewFrame3\n");
			textView.setText(returnValue);
			
			//Log.i("TAG",returnValue);
	
			mCamera.addCallbackBuffer(mVideoSource);
		}
	}

	public native String processMarker(Bitmap pTarget, byte[] pSource);

}
