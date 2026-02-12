const REPOSITORY = 'edgeandnode/amp';

export async function GET(request: Request) {
  const url = new URL(request.url);
  const parts = url.pathname.split('/');
  const version = parts[parts.length - 1];

  if (!version) {
    return new Response(undefined, { status: 400 });
  }

  const response = await fetch(`https://api.github.com/repos/${REPOSITORY}/releases/tags/${version}`, {
    headers: {
      'Accept': 'application/vnd.github.v3+json',
      'Authorization': `Bearer ${process.env.GITHUB_TOKEN}`
    },
  });

  const output = new Response(response.body, response);
  output.headers.set("Cache-Control", `public, max-age=60, s-maxage=60`);
  output.headers.delete("Content-Encoding");

  return output;
}
