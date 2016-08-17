package com.markerdetector;


import android.app.Activity;
import android.content.Context;
import android.opengl.GLSurfaceView;
import android.os.Bundle;
import android.view.Display;
import android.view.MotionEvent;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import android.opengl.GLES20;

public class GLMarker {

	private final String vertexShaderCode =
	        "attribute vec4 vPosition;" +
	        "void main() {" +
	        "  gl_Position = vPosition;" +
	        "}";

	    private final String fragmentShaderCode =
	        "precision mediump float;" +
	        "uniform vec4 vColor;" +
	        "void main() {" +
	        "  gl_FragColor = vColor;" +
	        "}";

	    
	private FloatBuffer vertexBuffer;
	float MarkerCoordinates[];
	float color[] = { 0.63671875f, 0.76953125f, 0.22265625f, 1.0f };

    int vertexShader;
    int pixelShader;
    int program;
	public void GLMarker()
	{
		MarkerCoordinates = new float[12];
		
	    vertexShader = loadShader(GLES20.GL_VERTEX_SHADER, vertexShaderCode);
	    pixelShader = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentShaderCode);
	    
	    program = GLES20.glCreateProgram();
	    GLES20.glAttachShader(program, vertexShader);
	    GLES20.glAttachShader(program, pixelShader);
	    GLES20.glLinkProgram(program);
		
	}
	
	
	public static int loadShader(int shaderType, String source) {
	    int[] gotVar = new int[]{ 0 };
	    int shader = GLES20.glCreateShader(shaderType);

	    /*if (shader == 0)
	        throw new FmtException(FmtException.GLES,"could not create shader: %s",getError());
*/
	    GLES20.glShaderSource(shader, source);
	    GLES20.glCompileShader(shader);

	    GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, gotVar, 0);
	    if (gotVar[0] == 0) {
	        GLES20.glGetShaderiv(shader, GLES20.GL_INFO_LOG_LENGTH, gotVar, 0);
	        if (gotVar[0] != 0) {
	            GLES20.glDeleteShader(shader);
	            //throw new FmtException(FmtException.GLES, "could not compile shader %d:\n%s\n",shaderType, GLES20.glGetShaderInfoLog(shader));
	        }
	    }

	    return shader;
	}
}
