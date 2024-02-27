export const handler = (event, context, callback) => {
  const { request } = event.Records[0].cf;
  const { headers } = request;

  const username = "username";
  const password = "password";

  const authString =
    "Basic " + Buffer.from(username + ":" + password).toString("base64");

  console.log("authString: ", authString);
  console.log(
    "headers.authorization === undefined: ",
    typeof headers.authorization === "undefined"
  );
  console.log("headers.authorization: ", headers.authorization);

  if (
    typeof headers.authorization === "undefined" ||
    headers.authorization[0].value !== authString
  ) {
    return callback(null, {
      body: "Unauthorized",
      headers: {
        "www-authenticate": [{ key: "WWW-Authenticate", value: "Basic" }],
      },
      status: "401",
      statusDescription: "Unauthorized",
    });
  }

  return callback(null, request);
};
