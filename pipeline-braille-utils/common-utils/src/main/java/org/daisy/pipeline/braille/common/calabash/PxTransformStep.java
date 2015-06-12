package org.daisy.pipeline.braille.common.calabash;

import java.net.URI;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;

import com.google.common.base.Predicate;
import static com.google.common.base.Predicates.alwaysFalse;
import static com.google.common.base.Predicates.alwaysTrue;
import static com.google.common.base.Predicates.instanceOf;
import com.google.common.collect.Iterables;

import com.xmlcalabash.core.XProcException;
import com.xmlcalabash.core.XProcRuntime;
import com.xmlcalabash.core.XProcStep;
import com.xmlcalabash.extensions.Eval;
import com.xmlcalabash.model.RuntimeValue;
import com.xmlcalabash.runtime.XAtomicStep;
import com.xmlcalabash.util.TreeWriter;

import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.QName;

import org.daisy.common.xproc.calabash.XProcStepProvider;
import org.daisy.pipeline.braille.common.CSSBlockTransform;
import org.daisy.pipeline.braille.common.CSSStyledDocumentTransform;
import org.daisy.pipeline.braille.common.MathMLTransform;
import org.daisy.pipeline.braille.common.Transform;
import org.daisy.pipeline.braille.common.Transform.Provider.DispatchingProvider;
import org.daisy.pipeline.braille.common.util.Tuple3;
import org.daisy.pipeline.braille.common.XProcTransform;

import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ReferenceCardinality;
import org.osgi.service.component.annotations.ReferencePolicy;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class PxTransformStep extends Eval {
	
	private final Iterable<Transform.Provider<XProcTransform>> providers;
	private final ReadableDocument pipeline;
	
	private static final QName _query = new QName("query");
	private static final QName _type = new QName("type");
	private static final QName _temp_dir = new QName("temp-dir");
	private static final QName _step = new QName("step");
	private static final QName _name = new QName("name");
	private static final QName _namespace = new QName("namespace");
	private static final QName _value = new QName("value");
	
	private PxTransformStep(XProcRuntime runtime, XAtomicStep step, Iterable<Transform.Provider<XProcTransform>> providers) {
		super(runtime, step);
		this.providers = providers;
		pipeline = new ReadableDocument(runtime);
		setInput("pipeline", pipeline);
	}
	
	private static class ReadableDocument extends com.xmlcalabash.io.ReadableDocument {
		private ReadableDocument(XProcRuntime runtime) {
			super(runtime);
		}
		private URI uri;
		private void setURI(URI uri) {
			this.uri = uri;
		}
		private boolean readDoc = false;
		@Override
		protected void readDoc() {
			if (readDoc) return;
			readDoc = true;
			documents.add(runtime.parse(uri.toASCIIString(), ""));
		}
	}
	
	private boolean setup = false;
	
	private void setup() {
		if (!setup) {
			String query = getOption(_query).getString();
			final String type = getOption(_type, "#any");
			Predicate<Object> filter;
			if (type.equals("mathml") || type.equals("math"))
				filter = instanceOf(MathMLTransform.Provider.class);
			else if (type.equals("css-block") || type.equals("block"))
				filter = instanceOf(CSSBlockTransform.Provider.class);
			else if (type.equals("css") || type.equals("embossed"))
				filter = instanceOf(CSSStyledDocumentTransform.Provider.class);
			else if (type.equals("#any"))
				filter = alwaysTrue();
			else
				filter = alwaysFalse();
			XProcTransform transform = null;
			try {
				transform = new DispatchingProvider<XProcTransform>(Iterables.filter(providers, filter)).get(query).iterator().next(); }
			catch (NoSuchElementException e) {
				throw new RuntimeException("Could not find an XProcTransform for query: " + query + " and type: " + type); }
			RuntimeValue tempDir = getOption(_temp_dir);
			Tuple3<URI,javax.xml.namespace.QName,Map<String,String>> t = transform.asXProc();
			URI href = t._1;
			pipeline.setURI(href);
			if (t._2 != null) {
				final QName step = new QName(t._2);
				setOption(_step, new RuntimeValue() { public QName getQName() { return step; }});
				throw new RuntimeException("p:library not supported due to a bug in cx:eval"); }
			if (t._3 != null || tempDir != null) {
				final Map<String,String> options = new HashMap<String,String>();
				if (t._3 != null)
					options.putAll(t._3);
				if (tempDir != null)
					options.put("temp-dir", tempDir.getString());
				setInput("options", new com.xmlcalabash.io.ReadableDocument(runtime) {
					private boolean readDoc = false;
					@Override
					protected void readDoc() {
						if (readDoc) return;
						readDoc = true;
						TreeWriter optionWriter = new TreeWriter(runtime);
						optionWriter.startDocument(step.getNode().getBaseURI());
						optionWriter.addStartElement(cx_options);
						optionWriter.startContent();
						for (String option : options.keySet()) {
							optionWriter.addStartElement(cx_option);
							optionWriter.addAttribute(_name, option);
							optionWriter.addAttribute(_namespace, "");
							optionWriter.addAttribute(_value, options.get(option));
							optionWriter.startContent();
							optionWriter.addEndElement(); }
						optionWriter.addEndElement();
						optionWriter.endDocument();
						documents.add(optionWriter.getResult()); }}); }}
		setup = true;
	}
	
	@Override
	public void run() throws SaxonApiException {
		try { setup(); }
		catch (Exception e) {
			logger.error("px:transform failed", e);
			throw new XProcException(step.getNode(), e); }
		super.run();
	}
	
	@Component(
		name = "px:transform",
		service = { XProcStepProvider.class },
		property = { "type:String={http://www.daisy.org/ns/pipeline/xproc}transform" }
	)
	public static class StepProvider implements XProcStepProvider {
		
		@Override
		public XProcStep newStep(XProcRuntime runtime, XAtomicStep step) {
			return new PxTransformStep(runtime, step, providers);
		}
		
		@Reference(
			name = "XProcTransformProvider",
			unbind = "unbindXProcTransformProvider",
			service = XProcTransform.Provider.class,
			cardinality = ReferenceCardinality.MULTIPLE,
			policy = ReferencePolicy.DYNAMIC
		)
		public void bindXProcTransformProvider(XProcTransform.Provider<?> provider) {
			providers.add((Transform.Provider<XProcTransform>)provider);
			logger.debug("Adding XProcTransform provider: {}", provider);
		}
		
		public void unbindXProcTransformProvider(XProcTransform.Provider<?> provider) {
			providers.remove(provider);
			logger.debug("Removing XProcTransform provider: {}", provider);
		}
		
		private List<Transform.Provider<XProcTransform>> providers = new ArrayList<Transform.Provider<XProcTransform>>();
		
	}
	
	private static final Logger logger = LoggerFactory.getLogger(PxTransformStep.class);
	
}
