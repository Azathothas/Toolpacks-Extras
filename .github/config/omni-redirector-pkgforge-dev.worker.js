// Domains
const SOAR_DEFAULT = 'https://soar.qaidvoid.dev';
const BINCACHE_DEFAULT = 'https://huggingface.co/datasets/pkgforge/bincache/resolve/main';
const PKGCACHE_DEFAULT = 'https://huggingface.co/datasets/pkgforge/pkgcache/resolve/main';

// Pre-compile domain regex patterns and their configurations
const DOMAIN_CONFIG = new Map([
  [
    /^https?:\/\/bincache\.pkgforge\.dev/i,
    {
      defaultTarget: BINCACHE_DEFAULT,
      pathMappings: new Map([
        ['aarch64', 'https://huggingface.co/datasets/pkgforge/bincache/resolve/main/aarch64-Linux'],
        ['aarch64-linux', 'https://huggingface.co/datasets/pkgforge/bincache/resolve/main/aarch64-Linux'],
        ['aarch64-Linux', 'https://huggingface.co/datasets/pkgforge/bincache/resolve/main/aarch64-Linux'],
        ['arm64_linux', 'https://huggingface.co/datasets/pkgforge/bincache/resolve/main/aarch64-Linux'],
        ['arm64_Linux', 'https://huggingface.co/datasets/pkgforge/bincache/resolve/main/aarch64-Linux'],
        ['x86_64', 'https://huggingface.co/datasets/pkgforge/bincache/resolve/main/x86_64-Linux'],
        ['x86_64-linux', 'https://huggingface.co/datasets/pkgforge/bincache/resolve/main/x86_64-Linux'],
        ['x86_64-Linux', 'https://huggingface.co/datasets/pkgforge/bincache/resolve/main/x86_64-Linux'],
        ['amd64_linux', 'https://huggingface.co/datasets/pkgforge/bincache/resolve/main/x86_64-Linux'],
        ['amd64_Linux', 'https://huggingface.co/datasets/pkgforge/bincache/resolve/main/x86_64-Linux']
      ])
    }
  ],
  [
    /^https?:\/\/pkgcache\.pkgforge\.dev/i,
    {
      defaultTarget: PKGCACHE_DEFAULT,
      pathMappings: new Map([
        ['aarch64', 'https://huggingface.co/datasets/pkgforge/pkgcache/resolve/main/aarch64-Linux'],
        ['aarch64-linux', 'https://huggingface.co/datasets/pkgforge/pkgcache/resolve/main/aarch64-Linux'],
        ['aarch64-Linux', 'https://huggingface.co/datasets/pkgforge/pkgcache/resolve/main/aarch64-Linux'],
        ['arm64_linux', 'https://huggingface.co/datasets/pkgforge/pkgcache/resolve/main/aarch64-Linux'],
        ['arm64_Linux', 'https://huggingface.co/datasets/pkgforge/pkgcache/resolve/main/aarch64-Linux'],
        ['x86_64', 'https://huggingface.co/datasets/pkgforge/pkgcache/resolve/main/x86_64-Linux'],
        ['x86_64-linux', 'https://huggingface.co/datasets/pkgforge/pkgcache/resolve/main/x86_64-Linux'],
        ['x86_64-Linux', 'https://huggingface.co/datasets/pkgforge/pkgcache/resolve/main/x86_64-Linux'],
        ['amd64_linux', 'https://huggingface.co/datasets/pkgforge/pkgcache/resolve/main/x86_64-Linux'],
        ['amd64_Linux', 'https://huggingface.co/datasets/pkgforge/pkgcache/resolve/main/x86_64-Linux']
      ])
    }
  ],
  [
    /^https?:\/\/soar\.pkgforge\.dev/i,
    {
      defaultTarget: SOAR_DEFAULT,
      pathMappings: new Map([
        ['docs', 'https://soar.qaidvoid.dev']
      ])
    }
  ]
]);

// Unified handler for all domains
function handleDomain(pathname, search, config) {
  const { defaultTarget, pathMappings } = config;

  // Check for specific path matches first
  for (const [prefix, target] of pathMappings) {
    if (pathname.startsWith('/' + prefix + '/')) {
      const remainingPath = pathname.slice(prefix.length + 2); // +2 for both slashes
      const baseUrl = target.endsWith('/') ? target.slice(0, -1) : target;
      return `${baseUrl}/${remainingPath}${search}`;
    }
  }
  
  // Default fallback
  return `${defaultTarget}${pathname}${search}`;
}

// Handle Incoming Requests
async function handleRequest(request) {
  const url = new URL(request.url);
  
  // Find matching domain configuration
  for (const [pattern, config] of DOMAIN_CONFIG) {
    if (pattern.test(url.href)) {
      const redirectUrl = handleDomain(url.pathname, url.search, config);
      return Response.redirect(redirectUrl, 301);
    }
  }
  
  // Return 404 if none match
  return new Response('Not Found', {
    status: 404,
    statusText: 'Not Found',
    headers: {
      'Content-Type': 'text/plain'
    }
  });
}

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request));
});
