import boto3

sess = boto3.session.Session(profile_name='postboard', region_name='us-east-1')
postboard = sess.resource('dynamodb').Table('Postboard')


postboard.put_item(Item={'BoardName': 'blah', 'Timestamp': 'foo'})

postboard.get_item(Key={'BoardName': 'blah'})
