package org.daisy.pipeline.braille.dotify.saxon.impl;

import java.util.NoSuchElementException;

import net.sf.saxon.expr.XPathContext;
import net.sf.saxon.lib.ExtensionFunctionCall;
import net.sf.saxon.lib.ExtensionFunctionDefinition;
import net.sf.saxon.om.Sequence;
import net.sf.saxon.om.StructuredQName;
import net.sf.saxon.trans.XPathException;
import net.sf.saxon.value.SequenceType;
import net.sf.saxon.value.StringValue;

import org.daisy.pipeline.braille.common.Query;
import static org.daisy.pipeline.braille.common.Query.util.query;
import org.daisy.pipeline.braille.dotify.DotifyTranslator;

import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ReferenceCardinality;
import org.osgi.service.component.annotations.ReferencePolicy;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Component(
	name = "dotify:translate",
	service = { ExtensionFunctionDefinition.class }
)
@SuppressWarnings("serial")
public class TranslateDefinition extends ExtensionFunctionDefinition {
	
	private DotifyTranslator.Provider provider = null;
	
	@Reference(
		name = "DotifyTranslatorProvider",
		unbind = "unbindTranslatorProvider",
		service = DotifyTranslator.Provider.class,
		cardinality = ReferenceCardinality.MANDATORY,
		policy = ReferencePolicy.STATIC
	)
	protected void bindTranslatorProvider(DotifyTranslator.Provider provider) {
		this.provider = provider;
	}
	
	protected void unbindTranslatorProvider(DotifyTranslator.Provider provider) {
		this.provider = null;
	}
	
	private static final StructuredQName funcname = new StructuredQName("dotify",
			"http://code.google.com/p/dotify/", "translate");
	
	@Override
	public StructuredQName getFunctionQName() {
		return funcname;
	}

	@Override
	public int getMinimumNumberOfArguments() {
		return 2;
	}

	@Override
	public int getMaximumNumberOfArguments() {
		return 2;
	}

	@Override
	public SequenceType[] getArgumentTypes() {
		return new SequenceType[] {
			SequenceType.SINGLE_STRING,
			SequenceType.SINGLE_STRING };
	}

	@Override
	public SequenceType getResultType(SequenceType[] suppliedArgumentTypes) {
		return SequenceType.OPTIONAL_STRING;
	}
	
	@Override
	public ExtensionFunctionCall makeCallExpression() {
		return new ExtensionFunctionCall() {
			
			@Override
			public Sequence call(XPathContext context, Sequence[] arguments) throws XPathException {
				try {
					Query query = query(arguments[0].head().getStringValue());
					DotifyTranslator translator;
					try { translator = provider.get(query).iterator().next(); }
					catch (NoSuchElementException e) {
						throw new RuntimeException("Could not find a translator for query: " + query); }
					String text = arguments[1].head().getStringValue();
					return new StringValue(translator.transform(text)); }
				catch (Exception e) {
					logger.error("dotify:translate failed", e);
					throw new XPathException("dotify:translate failed"); }
			}
		};
	}
	
	private static final Logger logger = LoggerFactory.getLogger(TranslateDefinition.class);
	
}
