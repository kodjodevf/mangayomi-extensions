// prettier-ignore
const mangayomiSources = [{
   "name": "Oduto - Boruto",
    "lang": "ar",
    "baseUrl":  "https://nb19u.blogspot.com",
    "apiUrl": "",
    "iconUrl": "https://blogger.googleusercontent.com/img/a/AVvXsEgKFmNQCUC7ARtXurDIwfOimVn3wogUvH7VaUOfjdutG44-cT4ajgh0KYkqSbRIoQ0b8YG3H6Edx-y1O3GW5SL88jymLZsO6cmS0QRtsp1y4gc24vmF4OGqyIY3PYSjxUYR1iJ5J-sP-00A7NwhNa19SPc0R_62KcuG6dbu2Rg-2YiMV1uUgaB0DGB6IBY_=s1600",
    "typeSource": "single",
    "itemType": 0,
    "version": "0.0.1",
    "isNsfw": false,
    "pkgPath": "manga/src/ar/oduto.js",
    "notes": "This Source Just For Boruto"
}];

class DefaultExtension extends MProvider {
  getPopular(_) {
    return {
      list: [
        {
          name: "BORUTO: Two Blue Vortex",
          imageUrl:
            "https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEggWB9vWPMqjEvIoDsJSO29OmW-srULDQD3cS9HJ8cDk0vq2jLwDerUX-i61CqmZf62eBVmWZwU5CgXi0p2lxhKrh2_nZum3p-k3q9QJ2uozove0QAbOKtbd1QPjytjrJc9UsL65X4BbFdgcicLDYubD9LgY1Kco8wyhDGm4YEOim8u1TL42gOFe16NaaEP/s3464/4D55C3C5-9168-4103-B45C-99B52B58B6A5.jpeg",
          link: "https://nb19u.blogspot.com/search/label/%D9%85%D8%A7%D9%86%D8%AC%D8%A7%20%D8%A8%D9%88%D8%B1%D9%88%D8%AA%D9%88?&max-results=4&m=1",
        },
      ],
      hasNextPage: false,
    };
  }
  getLatestUpdates(_) {
    return this.getPopular();
  }
}
