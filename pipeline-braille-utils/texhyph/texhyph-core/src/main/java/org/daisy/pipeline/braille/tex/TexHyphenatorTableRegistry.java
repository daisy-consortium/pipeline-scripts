package org.daisy.pipeline.braille.tex;

import java.net.URI;
import java.util.Locale;

import org.daisy.pipeline.braille.common.Provider;
import org.daisy.pipeline.braille.common.ResourceRegistry;

public class TexHyphenatorTableRegistry extends ResourceRegistry<TexHyphenatorTablePath>
	                                    implements TexHyphenatorTableProvider, TexHyphenatorTableResolver {
	
	@Override
	protected void register(TexHyphenatorTablePath path) {
		super.register(path);
		cache.invalidateCache();
	}
	
	@Override
	protected void unregister (TexHyphenatorTablePath path) {
		super.unregister(path);
		cache.invalidateCache();
	}
	
	/**
	 * Try to find a table based on the given locale.
	 * An automatic fallback mechanism is used: if nothing is found for
	 * language-COUNTRY-variant, then language-COUNTRY is searched, then language.
	 */
	public URI get(Locale locale) {
		return cache.get(locale);
	}
	
	private final DispatchingProvider<Locale,URI> dispatchingProvider = new DispatchingProvider<Locale,URI>() {
		public Iterable<? extends Provider<Locale,URI>> dispatch() {
			return paths.values();
		}
	};
	
	private final Provider<Locale,URI> provider = LocaleBasedProvider.<URI>newInstance(dispatchingProvider);
	private final CachedProvider<Locale,URI> cache = CachedProvider.<Locale,URI>newInstance(provider);
	
}