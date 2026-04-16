const repositories = ['amp', 'ampup'];

export async function GET(request: Request) {
  const [, , repository, , version] = new URL(request.url).pathname.split('/');
  if (!version || !repositories.includes(repository)) {
    return new Response(undefined, { status: 400 });
  }

  const response = await fetch(`https://api.github.com/repos/edgeandnode/${repository}/releases/tags/${version}`, {
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
