const REPOSITORY = 'edgeandnode/amp';

export async function GET() {
  const response = await fetch(`https://api.github.com/repos/${REPOSITORY}/releases/latest`, {
    headers: {
      'Accept': 'application/vnd.github.v3+json',
      'Authorization': `Bearer ${process.env.GITHUB_TOKEN}`
    },
  });

  const output = new Response(response.body, response);
  output.headers.set("Cache-Control", `public, max-age=60, s-maxage=60`);

  return output;
}
