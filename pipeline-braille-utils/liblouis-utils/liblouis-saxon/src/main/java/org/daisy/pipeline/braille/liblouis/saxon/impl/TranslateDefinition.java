package org.daisy.pipeline.braille.liblouis.saxon.impl;

import java.util.ArrayList;
import java.util.List;
import java.util.NoSuchElementException;

import net.sf.saxon.expr.XPathContext;
import net.sf.saxon.lib.ExtensionFunctionCall;
import net.sf.saxon.lib.ExtensionFunctionDefinition;
import net.sf.saxon.om.Sequence;
import net.sf.saxon.om.SequenceIterator;
import net.sf.saxon.om.StructuredQName;
import net.sf.saxon.trans.XPathException;
import net.sf.saxon.value.SequenceExtent;
import net.sf.saxon.value.SequenceType;
import net.sf.saxon.value.StringValue;

import org.daisy.pipeline.braille.common.Provider;
import static org.daisy.pipeline.braille.common.Provider.util.memoize;
import org.daisy.pipeline.braille.common.Transform;
import static org.daisy.pipeline.braille.common.Transform.Provider.util.dispatch;
import org.daisy.pipeline.braille.liblouis.LiblouisTranslator;

import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ReferenceCardinality;
import org.osgi.service.component.annotations.ReferencePolicy;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Component(
	name = "louis:translate",
	service = { ExtensionFunctionDefinition.class }
)
@SuppressWarnings("serial")
public class TranslateDefinition extends ExtensionFunctionDefinition {
	
	private static final StructuredQName funcname = new StructuredQName("louis",
			"http://liblouis.org/liblouis", "translate");
	
	@Reference(
		name = "LiblouisTranslatorProvider",
		unbind = "unbindLiblouisTranslatorProvider",
		service = LiblouisTranslator.Provider.class,
		cardinality = ReferenceCardinality.MULTIPLE,
		policy = ReferencePolicy.DYNAMIC
	)
	protected void bindLiblouisTranslatorProvider(LiblouisTranslator.Provider provider) {
		providers.add(provider);
		logger.debug("Adding LiblouisTranslator provider: {}", provider);
	}
	
	protected void unbindLiblouisTranslatorProvider(LiblouisTranslator.Provider provider) {
		providers.remove(provider);
		translators.invalidateCache();
		logger.debug("Removing LiblouisTranslator provider: {}", provider);
	}
	
	private List<Transform.Provider<LiblouisTranslator>> providers
	= new ArrayList<Transform.Provider<LiblouisTranslator>>();
	private Provider.MemoizingProvider<String,LiblouisTranslator> translators
	= memoize(dispatch(providers));
	
	public StructuredQName getFunctionQName() {
		return funcname;
	}
	
	@Override
	public int getMinimumNumberOfArguments() {
		return 2;
	}
	
	@Override
	public int getMaximumNumberOfArguments() {
		return 3;
	}
	
	public SequenceType[] getArgumentTypes() {
		return new SequenceType[] {
				SequenceType.SINGLE_STRING,
				SequenceType.ATOMIC_SEQUENCE,
				SequenceType.ATOMIC_SEQUENCE};
	}
	
	public SequenceType getResultType(SequenceType[] suppliedArgumentTypes) {
		return SequenceType.ATOMIC_SEQUENCE;
	}
	
	public ExtensionFunctionCall makeCallExpression() {
		return new ExtensionFunctionCall() {
			public Sequence call(XPathContext context, Sequence[] arguments) throws XPathException {
				try {
					String query = arguments[0].head().getStringValue();
					LiblouisTranslator translator;
					try { translator = translators.get(query).iterator().next(); }
					catch (NoSuchElementException e) {
						throw new RuntimeException("Could not find a translator for query: " + query); }
					String[] text = sequenceToArray(arguments[1]);
					if (arguments.length > 2) {
						String[] style = sequenceToArray(arguments[2]);
						return arrayToSequence(translator.transform(text, style)); }
					else
						return arrayToSequence(translator.transform(text)); }
				catch (Exception e) {
					logger.error("louis:translate failed", e);
					throw new XPathException("louis:translate failed"); }
			}
		};
	}
	
	private static String[] sequenceToArray(Sequence seq) throws XPathException {
		List<String> list = new ArrayList<String>();
		for (SequenceIterator<?> i = seq.iterate(); i.next() != null;)
			list.add(i.current().getStringValue());
		return list.toArray(new String[list.size()]);
	}
	
	private static Sequence arrayToSequence(String[] array) {
		List<StringValue> list = new ArrayList<StringValue>();
		for (String s : array)
			list.add(new StringValue(s));
		return new SequenceExtent<StringValue>(list);
	}
	
	private static final Logger logger = LoggerFactory.getLogger(TranslateDefinition.class);
	
}