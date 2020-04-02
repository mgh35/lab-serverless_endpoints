const fetch = require('node-fetch');

async function get_random_word(base_url, api_key) {
  const response = await fetch(`${base_url}/api/random_word?code=${api_key}`);
  return response.text()
}

async function resolve_text(text, base_url, api_key) {
  while (text.includes('@random_word')) {
    const random_word = await get_random_word(base_url, api_key);
    text = text.replace('@random_word', random_word);
  }
  return text;
}

async function post_message(board, message, base_url, api_key) {
  text = await resolve_text(message.text, base_url, api_key);
  return {
    status: 200,
    body: {
      'board': board,
      'text': text
    },
    headers: {
      "content-type": "application/json",
    },
  };
}

function get_messages(board) {
  return {
    status: 200,
    body: {
      'board': board
    },
    headers: {
      "content-type": "application/json",
    },
  };
}

module.exports = async function (context, req) {
  var board = req.params.boardName;
  var method = req.method;
  var base_url = req.url.replace(/^(https?:\/\/[^\/]+)\/.*$/, '$1');
  var api_key = req.query.code;


  if (method.toUpperCase() === 'POST') {
    return await post_message(board, context.req.body, base_url, api_key);
  } else if (method.toUpperCase() === 'GET') {
    return get_messages(board);
  } else {
    return {
      status: 403,
      body: {
        'error': `Unsupported method: ${method}`,
      },
      headers: {
        "content-type": "application/json",
      },
    };
  }
};
