# ScrapeCreators Endpoint Catalog

Every scraping endpoint from the live OpenAPI spec (`https://docs.scrapecreators.com/openapi.json`
— the canonical source for all endpoints), verified with a real call through the Chorus proxy on
2026-06-09. All requests are GET. The example params column shows a parameter set that returned a
successful response; pass any path directly to the wrapper:
`bash scripts/scrapecreators.sh <path> [--param value ...]`.
Account endpoints (`/v1/account/*`) are omitted — this skill is for scraping data.

## amazon

| Path | Example params | Notes |
|---|---|---|
| `/v1/amazon/shop` | `url=https://www.amazon.com/shop/sydneydelrey` |  |

## bluesky

| Path | Example params | Notes |
|---|---|---|
| `/v1/bluesky/post` | `url=https://bsky.app/profile/espn.com/post/3lqdfq7fkvm2g` |  |
| `/v1/bluesky/profile` | `handle=espn.com` |  |
| `/v1/bluesky/user/posts` | `handle=espn.com` `user_id=did:plc:x7d6j54pm22ufehkes6jo4jf` |  |

## detect-age-gender

| Path | Example params | Notes |
|---|---|---|
| `/v1/detect-age-gender` | `url=https://twitter.com/levelsio` |  |

## facebook

| Path | Example params | Notes |
|---|---|---|
| `/v1/facebook/adLibrary/ad` | `id=1809250469800080` `trim=true` |  |
| `/v1/facebook/adLibrary/ad/transcript` | `id=1809250469800080` |  |
| `/v1/facebook/adLibrary/company/ads` | `pageId=367152833370567` `trim=true` |  |
| `/v1/facebook/adLibrary/search/ads` | `country=US` `query=running` `trim=true` |  |
| `/v1/facebook/adLibrary/search/companies` | `query=nike` |  |
| `/v1/facebook/event/details` | `id=2255360061870188` |  |
| `/v1/facebook/events` | `url=https://www.facebook.com/events/explore/saint-petersburg-florida/111326725552547` |  |
| `/v1/facebook/events/search` | `query=Event name or description` |  |
| `/v1/facebook/group/posts` | `url=https://www.facebook.com/groups/1270525996445602/` |  |
| `/v1/facebook/marketplace/item` | `id=1656586118821988` |  |
| `/v1/facebook/marketplace/location/search` | `query=Austin` |  |
| `/v1/facebook/marketplace/search` | `lat=30.2677` `lng=-97.7475` `query=bike` |  |
| `/v1/facebook/post` | `url=https://www.facebook.com/reel/1535656380759655` |  |
| `/v1/facebook/post/comment/replies` | `expansion_token=...` `feedback_id=...` | Tokens come from a prior `/v1/facebook/post/comments` response. |
| `/v1/facebook/post/comments` | `feedback_id=ZmVlZGJhY2s6MTQ0NzY1NjMyMzM4Mzg0OA==` `url=https://www.facebook.com/reel/753347914167361` |  |
| `/v1/facebook/post/transcript` | `url=https://www.facebook.com/reel/1535656380759655` |  |
| `/v1/facebook/profile` | `url=https://www.facebook.com/mantraindianfolsom` |  |
| `/v1/facebook/profile/events` | `url=https://www.facebook.com/brickyardoldtown` |  |
| `/v1/facebook/profile/photos` | `url=https://www.facebook.com/Spurs` |  |
| `/v1/facebook/profile/posts` | `pageId=100063669491743` `url=https://www.facebook.com/pacemorby` |  |
| `/v1/facebook/profile/reels` | `url=https://www.facebook.com/pacemorby` |  |

## github

| Path | Example params | Notes |
|---|---|---|
| `/v1/github/repository` | `url=https://github.com/torvalds/linux` |  |
| `/v1/github/trending/developers` |  |  |
| `/v1/github/trending/repositories` |  |  |
| `/v1/github/user` | `handle=torvalds` `url=https://github.com/torvalds` |  |
| `/v1/github/user/activity` | `handle=kentcdodds` `url=https://github.com/torvalds` |  |
| `/v1/github/user/contributions` | `handle=torvalds` `url=https://github.com/torvalds` |  |
| `/v1/github/user/followers` | `handle=torvalds` `url=https://github.com/torvalds` |  |
| `/v1/github/user/following` | `handle=kentcdodds` `url=https://github.com/kentcdodds` |  |
| `/v1/github/user/repositories` | `handle=torvalds` `url=https://github.com/kentcdodds` |  |

## google

| Path | Example params | Notes |
|---|---|---|
| `/v1/google/ad` | `url=https://adstransparency.google.com/advertiser/AR01614014350098432001/creative/CR10449491775734153217` |  |
| `/v1/google/adLibrary/advertisers/search` | `query=lululemon` `region=US` |  |
| `/v1/google/company/ads` | `domain=lululemon.com` `get_ad_details=false` `region=US` |  |
| `/v1/google/search` | `query=austen allred` `region=US` |  |

## instagram

| Path | Example params | Notes |
|---|---|---|
| `/v1/instagram/audio/reels` | `audio_id=1392969992841787` |  |
| `/v1/instagram/basic-profile` | `userId=314216` |  |
| `/v1/instagram/post` | `region=US` `trim=true` `url=https://www.instagram.com/reel/DOq6eV6iIgD` |  |
| `/v1/instagram/profile` | `handle=jane` `trim=true` |  |
| `/v1/instagram/reels/trending` |  |  |
| `/v1/instagram/search/hashtag` | `hashtag=makeup` |  |
| `/v1/instagram/search/profiles` | `query=fitness coach` |  |
| `/v1/instagram/user/embed` | `handle=jane` |  |
| `/v1/instagram/user/highlight/detail` | `id=18067016518767507` |  |
| `/v1/instagram/user/highlights` | `handle=jane` `user_id=2700692569` |  |
| `/v1/instagram/user/reels` | `handle=jane` `trim=true` `user_id=2700692569` |  |
| `/v2/instagram/media/transcript` | `url=https://www.instagram.com/reel/DOq6eV6iIgD` | intermittent 500; retry once |
| `/v2/instagram/post/comments` | `url=https://www.instagram.com/reel/DOq6eV6iIgD` |  |
| `/v2/instagram/reels/search` | `query=dogs` |  |
| `/v2/instagram/user/posts` | `handle=jane` `trim=true` |  |

## kick

| Path | Example params | Notes |
|---|---|---|
| `/v1/kick/clip` | `url=https://kick.com/xqc/clips/clip_01JGJHB6CEVFCQRYTVPM8DW892` |  |

## komi

| Path | Example params | Notes |
|---|---|---|
| `/v1/komi` | `url=https://kimkardashian.komi.io/` |  |

## kwai

| Path | Example params | Notes |
|---|---|---|
| `/v1/kwai/post` | `url=https://www.kwai.com/@KwaiBrasilOficial/photo/5193363430624671876` |  |
| `/v1/kwai/profile` | `handle=KwaiBrasilOficial` `url=https://www.kwai.com/@KwaiBrasilOficial` |  |
| `/v1/kwai/user/posts` | `handle=KwaiBrasilOficial` `url=https://www.kwai.com/@KwaiBrasilOficial` |  |

## linkbio

| Path | Example params | Notes |
|---|---|---|
| `/v1/linkbio` | `url=https://lnk.bio/msjennafischer` |  |

## linkedin

| Path | Example params | Notes |
|---|---|---|
| `/v1/linkedin/ad` | `url=https://www.linkedin.com/ad-library/detail/666281156` |  |
| `/v1/linkedin/ads/search` | `company=microsoft` |  |
| `/v1/linkedin/company` | `url=https://linkedin.com/company/shopify` |  |
| `/v1/linkedin/company/posts` | `url=https://linkedin.com/company/shopify` |  |
| `/v1/linkedin/post` | `url=https://www.linkedin.com/pulse/being-father-has-made-me-better-leader-vice-versa-austen-allred/` |  |
| `/v1/linkedin/post/transcript` | `url=https://www.linkedin.com/posts/gemini-35-flash-is-a-step-forward-for-google-ugcPost-7465082215316525056-MHBd/` |  |
| `/v1/linkedin/profile` | `url=https://www.linkedin.com/in/parrsam/` |  |
| `/v1/linkedin/search/posts` | `query=ai agents` |  |

## linkme

| Path | Example params | Notes |
|---|---|---|
| `/v1/linkme` | `url=https://link.me/danucd` |  |

## linktree

| Path | Example params | Notes |
|---|---|---|
| `/v1/linktree` | `url=https://linktr.ee/miguelangeles` |  |

## pillar

| Path | Example params | Notes |
|---|---|---|
| `/v1/pillar` | `url=https://pillar.io/angelstrife` |  |

## pinterest

| Path | Example params | Notes |
|---|---|---|
| `/v1/pinterest/board` | `trim=true` `url=https://www.pinterest.com/lizmrodgers/moms-night/` |  |
| `/v1/pinterest/pin` | `trim=true` `url=https://www.pinterest.com/pin/1124351863225567517/` |  |
| `/v1/pinterest/search` | `query=Italian Pot Roast` `trim=true` |  |
| `/v1/pinterest/user/boards` | `handle=broadstbullycom` `trim=true` |  |

## reddit

| Path | Example params | Notes |
|---|---|---|
| `/v1/reddit/post/comments` | `trim=true` `url=https://www.reddit.com/r/AskReddit/comments/ablzuq/people_who_havent_pooped_in_2019_yet_why_are_you/` |  |
| `/v1/reddit/post/transcript` | `url=https://www.reddit.com/r/youseeingthisshit/comments/1oiu9xm/football_nostalgiasaints_punter_head_coach_cant/` |  |
| `/v1/reddit/search` | `query=python` `trim=true` |  |
| `/v1/reddit/subreddit` | `subreddit=AskReddit` `trim=true` |  |
| `/v1/reddit/subreddit/details` | `subreddit=AskReddit` `url=https://www.reddit.com/r/AbsoluteUnits/` |  |
| `/v1/reddit/subreddit/search` | `subreddit=AskReddit` |  |

## rumble

| Path | Example params | Notes |
|---|---|---|
| `/v1/rumble/channel/videos` | `handle=CuteCats223` `url=https://rumble.com/c/CuteCats223` |  |
| `/v1/rumble/search` | `query=funny cats` |  |
| `/v1/rumble/video` | `url=https://rumble.com/v79xhhm-discovery-why-glenn-wants-israel-to-sue-the-new-york-times.html` |  |
| `/v1/rumble/video/comments` | `url=https://rumble.com/v792vns-the-splc-is-a-deceitful-and-poisonous-group.-but-was-their-behavior-crimina.html?e9s=rel_v2_ep` | intermittent 503 |
| `/v1/rumble/video/transcript` | `url=https://rumble.com/valm19-funny-cat-funny-cat.html` |  |

## snapchat

| Path | Example params | Notes |
|---|---|---|
| `/v1/snapchat/profile` | `handle=zane` |  |

## soundcloud

| Path | Example params | Notes |
|---|---|---|
| `/v1/soundcloud/artist` | `handle=kehlanimusic` `url=https://soundcloud.com/kehlanimusic` | consistent 500 |
| `/v1/soundcloud/artist/tracks` | `handle=kehlanimusic` `url=https://soundcloud.com/kehlanimusic` | consistent 500 |
| `/v1/soundcloud/track` | `url=https://soundcloud.com/kehlanimusic/lights-on-feat-big-sean` | consistent 500 |

## spotify

| Path | Example params | Notes |
|---|---|---|
| `/v1/spotify/album` | `id=0pgrg7phBbnwGJ2HBEl9EG` `url=https://open.spotify.com/album/0pgrg7phBbnwGJ2HBEl9EG` |  |
| `/v1/spotify/artist` | `id=0cGUm45nv7Z6M6qdXYQGTX` `url=https://open.spotify.com/artist/0cGUm45nv7Z6M6qdXYQGTX` |  |
| `/v1/spotify/podcast` | `id=3mliji9352UAk3XnWElnDV` `url=https://open.spotify.com/show/3mliji9352UAk3XnWElnDV` |  |
| `/v1/spotify/podcast/episodes` | `id=4rOoJ6Egrf8K2IrywzwOMk` `url=https://open.spotify.com/show/4rOoJ6Egrf8K2IrywzwOMk` |  |
| `/v1/spotify/search` | `query=my first million` |  |
| `/v1/spotify/track` | `id=1ITJflybJsfarsUtiBvkfK` `url=https://open.spotify.com/track/1ITJflybJsfarsUtiBvkfK` |  |

## threads

| Path | Example params | Notes |
|---|---|---|
| `/v1/threads/post` | `trim=true` `url=https://www.threads.com/@trendspider/post/DIU8naHS6q_` |  |
| `/v1/threads/profile` | `handle=trendspider` |  |
| `/v1/threads/search` | `query=basketball` `trim=true` |  |
| `/v1/threads/search/users` | `query=shams` |  |
| `/v1/threads/user/posts` | `handle=trendspider` `trim=true` |  |

## tiktok

| Path | Example params | Notes |
|---|---|---|
| `/v1/tiktok/creators/popular` |  |  |
| `/v1/tiktok/get-trending-feed` | `region=US` `trim=true` |  |
| `/v1/tiktok/hashtags/popular` | `period=7` | 400; TikTok removed the source page |
| `/v1/tiktok/product` | `region=US` `url=https://www.tiktok.com/shop/pdp/goli-ashwagandha-gummies-with-vitamin-d-ksm-66-vegan-non-gmo/1729587769570529799` |  |
| `/v1/tiktok/profile` | `handle=stoolpresidente` `user_id=6659752019493208069` |  |
| `/v1/tiktok/profile/region` | `handle=stoolpresidente` |  |
| `/v1/tiktok/search/hashtag` | `hashtag=funny` `region=US` `trim=true` |  |
| `/v1/tiktok/search/keyword` | `query=funny` `region=US` `trim=true` |  |
| `/v1/tiktok/search/top` | `query=funny` `region=US` |  |
| `/v1/tiktok/search/users` | `query=shakira` `trim=true` |  |
| `/v1/tiktok/shop/product/reviews` | `product_id=1731578642912612516` `region=US` |  |
| `/v1/tiktok/shop/products` | `region=US` `url=https://www.tiktok.com/shop/store/goli-nutrition/7495794203056835079` |  |
| `/v1/tiktok/shop/search` | `query=shoes` `region=US` |  |
| `/v1/tiktok/song` | `clipId=7439295283975702544` |  |
| `/v1/tiktok/song/videos` | `clipId=7439295283975702544` |  |
| `/v1/tiktok/user/audience` | `handle=shakira` |  |
| `/v1/tiktok/user/followers` | `handle=stoolpresidente` `trim=true` `user_id=6659752019493208069` |  |
| `/v1/tiktok/user/following` | `handle=stoolpresidente` `trim=true` |  |
| `/v1/tiktok/user/live` | `handle=thejustalex` |  |
| `/v1/tiktok/user/showcase` | `handle=mrtiktokreviews` `region=US` |  |
| `/v1/tiktok/video/comment/replies` | `comment_id=7623828115408274207` `url=https://www.tiktok.com/@stoolpresidente/video/7623818255903329566` |  |
| `/v1/tiktok/video/comments` | `trim=true` `url=https://www.tiktok.com/@stoolpresidente/video/7623818255903329566` |  |
| `/v1/tiktok/video/transcript` | `url=https://www.tiktok.com/@stoolpresidente/video/7499229683859426602` |  |
| `/v2/tiktok/video` | `region=US` `trim=true` `url=https://www.tiktok.com/@randomspamvideos25/video/7251387037834595630` |  |
| `/v3/tiktok/profile/videos` | `handle=stoolpresidente` `region=US` `trim=true` |  |

## truthsocial

| Path | Example params | Notes |
|---|---|---|
| `/v1/truthsocial/post` | `url=https://truthsocial.com/@realDonaldTrump/posts/114315219437063160` |  |
| `/v1/truthsocial/profile` | `handle=realDonaldTrump` |  |
| `/v1/truthsocial/user/posts` | `handle=realDonaldTrump` `trim=true` `user_id=107780257626128497` |  |

## twitch

| Path | Example params | Notes |
|---|---|---|
| `/v1/twitch/clip` | `url=https://www.twitch.tv/staryuuki/clip/CloudySavageMarjoramRuleFive--ErzsYbE7UWvgCMQ?filter=clips&range=all&sort=time` |  |
| `/v1/twitch/profile` | `handle=ishowspeed` |  |
| `/v1/twitch/user/schedule` | `handle=emongg` |  |
| `/v1/twitch/user/videos` | `handle=ishowspeed` |  |

## twitter

| Path | Example params | Notes |
|---|---|---|
| `/v1/twitter/community` | `url=https://x.com/i/communities/1926186499399139650` |  |
| `/v1/twitter/community/tweets` | `url=https://x.com/i/communities/1926186499399139650` |  |
| `/v1/twitter/profile` | `handle=Austen` |  |
| `/v1/twitter/tweet` | `trim=true` `url=https://x.com/TheoVon/status/1916982720317821050` |  |
| `/v1/twitter/tweet/transcript` | `url=https://x.com/TheoVon/status/1916982720317821050` |  |
| `/v1/twitter/user-tweets` | `handle=levelsio` `trim=true` |  |

## youtube

| Path | Example params | Notes |
|---|---|---|
| `/v1/youtube/channel` | `channelId=UC-9-kyTW8ZkZNDHQJ6FgpwQ` `handle=ThePatMcAfeeShow` `url=https://www.youtube.com/@ThePatMcAfeeShow` |  |
| `/v1/youtube/channel-videos` | `channelId=UC-9-kyTW8ZkZNDHQJ6FgpwQ` `handle=ThePatMcAfeeShow` |  |
| `/v1/youtube/channel/community-posts` | `channelId=UCX6OQ3DkcsbYNE6H8uQQuVA` `handle=MrBeast` |  |
| `/v1/youtube/channel/lives` | `channelId=UCWsDFcIhY2DBi3GB5uykGXA` `handle=IShowSpeed` |  |
| `/v1/youtube/channel/playlists` | `channelId=UCX6OQ3DkcsbYNE6H8uQQuVA` `handle=MrBeast` |  |
| `/v1/youtube/channel/shorts` | `channelId=UC-9-kyTW8ZkZNDHQJ6FgpwQ` `handle=starterstory` |  |
| `/v1/youtube/community-post` | `url=https://www.youtube.com/post/Ugkxvj2KoApYAXoqLWnKVr6zZe5JjeHrQeP8` |  |
| `/v1/youtube/playlist` | `playlist_id=PLP32wGpgzmIlInfgKVFfCwVsxgGqZNIiS` |  |
| `/v1/youtube/search` | `query=funny cats` `region=US` |  |
| `/v1/youtube/search/hashtag` | `hashtag=funny` |  |
| `/v1/youtube/shorts/trending` |  |  |
| `/v1/youtube/video` | `url=https://www.youtube.com/watch?v=Y2Ah_DFr8cw` |  |
| `/v1/youtube/video/comment/replies` | `continuationToken=...` | Token is `repliesContinuationToken` from a prior `/v1/youtube/video/comments` response. |
| `/v1/youtube/video/comments` | `url=https://www.youtube.com/watch?v=dQw4w9WgXcQ` |  |
| `/v1/youtube/video/transcript` | `url=https://www.youtube.com/watch?v=bjVIDXPP7Uk` |  |
