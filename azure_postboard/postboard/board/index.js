const fetch = require('node-fetch');
const MongoClient = require('mongodb').MongoClient;


function mongodb_connection_string() {
  return `mongodb://${process.env.MONGODB_NAME}:${process.env.MONGODB_KEY}@${process.env.MONGODB_NAME}.documents.azure.com:10255/mean-dev?ssl=true&sslverifycertificate=false`;
}


async function board_messages(board) {
  return new Promise((resolve, reject) => {
    MongoClient.connect(mongodb_connection_string(), function(err, conn) {
      if (err) {
        return reject(err);
      }
      conn
          .db('postboard')
          .collection('boards')
          .findOne({'boardName': board})
          .then(doc => {
            resolve(doc.messages);
          })
          .catch(err => {
            return reject(err);
          })
          .finally(() => {
            conn.close();
          });
    });
  });
}

async function add_message_to_board(board, message) {
  return new Promise((resolve, reject) => {
    MongoClient.connect(mongodb_connection_string(), function(err, conn) {
      if (err) {
        return reject(err);
      }
      conn
          .db('postboard')
          .collection('boards')
          .update({'boardName': board}, {$push: {'messages': message}})
          .finally(() => {
            conn.close();
          });
      resolve(message);
    });
  });
}

async function get_random_word(base_url, api_key) {
  const response = await fetch(`${base_url}/api/random_word?code=${api_key}`);
  return response.text();
}

async function resolve_text(text, base_url, api_key) {
  while (text.includes('@random_word')) {
    const random_word = await get_random_word(base_url, api_key);
    text = text.replace('@random_word', random_word);
  }
  return text;
}

async function post_message(board, message, base_url, api_key) {
  const text = await resolve_text(message.text, base_url, api_key);
  await add_message_to_board(board, text);

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

async function get_messages(board) {
  const messages = await board_messages(board);
  console.log(`Got messages: ${messages}`);
  return {
    status: 200,
    body: {
      'board': board,
      'messages': messages,
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
    return await get_messages(board);
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
