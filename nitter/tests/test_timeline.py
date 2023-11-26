from base import BaseTestCase, Timeline
from parameterized import parameterized

normal = [['jack'], ['elonmusk']]

after = [['jack', '1681686036294803456'],
         ['elonmusk', '1681686036294803456']]

no_more = [['mobile_test_8?cursor=1000']]

empty = [['emptyuser'], ['mobile_test_10']]

protected = [['mobile_test_7'], ['Empty_user']]

photo_rail = [['mobile_test', ['Bo0nDsYIYAIjqVn', 'BoQbwJAIUAA0QCY', 'BoQbRQxIIAA3FWD', 'Bn8Qh8iIIAABXrG']]]


class TweetTest(BaseTestCase):
    @parameterized.expand(normal)
    def test_timeline(self, username):
        self.open_nitter(username)
        self.assert_element_present(Timeline.older)
        self.assert_element_absent(Timeline.newest)
        self.assert_element_absent(Timeline.end)
        self.assert_element_absent(Timeline.none)

    @parameterized.expand(after)
    def test_after(self, username, cursor):
        self.open_nitter(f'{username}?cursor={cursor}')
        self.assert_element_present(Timeline.newest)
        self.assert_element_present(Timeline.older)
        self.assert_element_absent(Timeline.end)
        self.assert_element_absent(Timeline.none)

    @parameterized.expand(no_more)
    def test_no_more(self, username):
        self.open_nitter(username)
        self.assert_text('No more items', Timeline.end)
        self.assert_element_present(Timeline.newest)
        self.assert_element_absent(Timeline.older)

    @parameterized.expand(empty)
    def test_empty(self, username):
        self.open_nitter(username)
        self.assert_text('No items found', Timeline.none)
        self.assert_element_absent(Timeline.newest)
        self.assert_element_absent(Timeline.older)
        self.assert_element_absent(Timeline.end)

    @parameterized.expand(protected)
    def test_protected(self, username):
        self.open_nitter(username)
        self.assert_text('This account\'s tweets are protected.', Timeline.protected)
        self.assert_element_absent(Timeline.newest)
        self.assert_element_absent(Timeline.older)
        self.assert_element_absent(Timeline.end)

    #@parameterized.expand(photo_rail)
    #def test_photo_rail(self, username, images):
        #self.open_nitter(username)
        #self.assert_element_visible(Timeline.photo_rail)
        #for i, url in enumerate(images):
            #img = self.get_attribute(Timeline.photo_rail + f' a:nth-child({i + 1}) img', 'src')
            #self.assertIn(url, img)
