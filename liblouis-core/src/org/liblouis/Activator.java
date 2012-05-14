package org.liblouis;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.URL;
import java.util.Enumeration;

import org.osgi.framework.Bundle;
import org.osgi.service.component.ComponentContext;

public class Activator {

	private static File nativePath = null;

	public static File getNativePath() {
		return nativePath;
	}

	public void start(ComponentContext context) {
		nativePath = context.getBundleContext().getDataFile("native");
		if (!nativePath.exists()) {
			nativePath.mkdir();
			Bundle bundle = context.getBundleContext().getBundle();
			if (bundle.getEntry("/native/linux") != null) {
				Enumeration<String> paths = bundle.getEntryPaths("/native/linux");
				if (paths != null) {
					System.out.println("Unpacking liblouis binaries...");
					while (paths.hasMoreElements()) {
						URL tableURL = bundle.getEntry(paths.nextElement());
						String url = tableURL.toExternalForm();
						String fileName = url.substring(url.lastIndexOf('/')+1, url.length());
						File file = new File(nativePath.getAbsolutePath() + File.separator + fileName);
						try {
							unpack(tableURL, file);
							chmod775(file);
							System.out.println(fileName);
						} catch (Exception e) {
							System.out.println("Exception occured during unpacking of file '" + fileName + "'");
							e.printStackTrace();
						}
					}
				}
			}
		}
	}

	private static void unpack(URL url, File file) throws Exception {
		file.createNewFile();
		FileOutputStream writer = new FileOutputStream(file);
		url.openConnection();
		InputStream reader = url.openStream();
		byte[] buffer = new byte[153600];
		int bytesRead = 0;
		while ((bytesRead = reader.read(buffer)) > 0) {
			writer.write(buffer, 0, bytesRead);
			buffer = new byte[153600];
		}
		writer.close();
		reader.close();
	}

	private static void chmod775(File file) throws Exception {
		Runtime.getRuntime().exec(new String[] { "chmod", "775", file.getAbsolutePath() }).waitFor();
	}
}