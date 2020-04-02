module.exports = async function (context) {
  var words = Array('foo', 'bar', 'blah', 'boop');
  var word = words[Math.floor(Math.random() * words.length)];
  return {
    status: 200,
    body: word,
    headers: {
      "content-type": "text/plain",
    },
  };
};
