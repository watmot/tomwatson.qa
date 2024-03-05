export const handler = (event, context, callback) => {
  const { request } = event.Records[0].cf;

  if (request.uri.endsWith("/")) {
    request.uri += "index.html";
  } else if (/.*\/([^.]*)$/.test(request.uri)) {
    request.uri += "/index.html";
  }

  callback(null, request);
};
