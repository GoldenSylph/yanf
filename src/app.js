App = {
  web3Provider: null,
  contracts: {},
  account: '0x0',
  loading: false,
  contractInstance: null,

  init: async () => {
    await App.initWeb3();
    await App.initAll();
    await App.render();
  },

  initWeb3: async () => {
    if (typeof web3 !== 'undefined') {
      App.web3Provider = web3.currentProvider;
      web3 = new Web3(web3.currentProvider);
    } else {
      window.alert("Please connect to Metamask.");
    }
    if (window.ethereum) {
      window.web3 = new Web3(ethereum);
      try {
        await ethereum.enable();
      } catch (error) {
        window.alert(error);
      }
    }
    else if (window.web3) {
      App.web3Provider = web3.currentProvider;
      window.web3 = new Web3(web3.currentProvider);
    }
    else {
      console.log('Non-Ethereum browser detected. You should consider trying MetaMask!');
      window.alert("Non-Ethereum browser detected. You should consider trying MetaMask!");
    }
  },

  initAll: async () => {
    App.ipfs = window.IpfsHttpClient({host: 'ipfs.infura.io', port: '5001', protocol: 'https'});
    App.converter = new showdown.Converter();

    const YANFManagerSimplifiedContractJSON = await $.getJSON('YANFManagerSimplified.json');
    App.contracts.YANFManagerSimplified = TruffleContract(YANFManagerSimplifiedContractJSON);
    App.contracts.YANFManagerSimplified.setProvider(App.web3Provider);
  },

  render: async () => {
    if (App.loading) {
      return;
    }
    App.setLoading(true);
    App.account = web3.eth.accounts[0];
    $('#viewing_author').html(App.account);
    await App.searchBy(App.account);
    App.setLoading(false);
  },

  publish: async () => {

    const title = $('#title').val();
    const articleContent = simplemde.value();

    if ((title === '' || title === null)
      || (articleContent === null || articleContent === '')) {
      return;
    }

    const bufferedContent = window.IpfsHttpClient.Buffer.from(articleContent);

    var articleHash;
    await App.ipfs.add(bufferedContent)
      .then((value) => {
        articleHash = value[0].hash;
      })
      .catch((error) => {
        console.log('IPFS add error: ' + error);
        window.alert('Sorry, we can not connect to the IPFS.');
      });

    await App.contracts.YANFManagerSimplified.deployed()
      .then((instance) => {
        return instance.publish(title, articleHash,
            {from: App.account, value: web3.toWei(1, 'finney')})
      })
      .then((result) => {
        window.alert('Your article is successfully published, you can either now ' +
        'or later reload the page to see results.');
      })
      .catch((error) => {
        console.log('An error occurred during the publishing: ' + error);
        window.alert('Sorry, your article was not published. You can contact to us, so we could help you.');
      });

    $('#publishModal').modal('hide');
  },

  search: async () => {
    console.log('custom search called');
    App.searchBy($('#author').val());
  },

  searchBy: async (authorAddr) => {
    if (authorAddr === null || authorAddr === '') {
      return;
    }

    App.setLoading(true);
    const authorAddress = authorAddr;

    var articlesCount = 0;

    await App.contracts.YANFManagerSimplified.deployed()
      .then((instance) => {
        return instance.getArticleCount.call(authorAddress, {from: App.account});
      })
      .then((result) => {
        console.log("articles found: " + result);
        articlesCount = result;
      })
      .catch((error) => {
        console.log('An error occurred during the searching: ' + error);
        window.alert('Sorry, we can not proceed this search request. You can contact to us, so we could help you.');
      });

    if (articlesCount == 0) {
      $('#article_container').html('<h2>Sorry, this author has\'t got any articles.</h2>');
    } else {
      for (i = 0; i < articlesCount; i++) {

        var articleTitle;
        var articleIPFSLink;
        var articleContent;

        await App.contracts.YANFManagerSimplified.deployed()
          .then((instance) => {
            return instance.getArticleTitleByIndex.call(authorAddress, i, {from: App.account});
          })
          .then((result) => {
            articleTitle = result;
          })
          .catch((error) => {
            console.log('An error occurred during the title searching: ' + error);
            window.alert('Sorry, we can not proceed this search request. You can contact to us, so we could help you.');
          });

        await App.contracts.YANFManagerSimplified.deployed()
          .then((instance) => {
            return instance.getArticleContentHashByIndex.call(authorAddress, i, {from: App.account});
          })
          .then((result) => {
            articleIPFSLink = result;
          })
          .catch((error) => {
            console.log('An error occurred during the content hash searching: ' + error);
            window.alert('Sorry, we can not proceed this search request. You can contact to us, so we could help you.');
          });

        await App.ipfs.cat(articleIPFSLink)
          .then((value) => {
            articleContent = value.toString();
          })
          .catch((error) => {
            console.log('IPFS cat error: ' + error);
            window.alert('Sorry, we can not connect to the IPFS.');
          });

        articleContent = App.converter.makeHtml(articleContent);
        var newArticle = App.wrapToHTML(authorAddress, articleIPFSLink, articleTitle, articleContent);
        $('#article_container').prepend(newArticle);
      }
    }

    App.setLoading(false);
  },

  getHTMLFromMarkdown: (markdown) => {
    var converter = new showdown.Converter();
    return converter.makeHtml(markdown);
  },

  scrollFunction: () => {
    if (document.body.scrollTop > 100 || document.documentElement.scrollTop > 100) {
      document.getElementById("toTopBtn").style.display = "block";
    } else {
      document.getElementById("toTopBtn").style.display = "none";
    }
  },

  topFunction: () => {
    document.body.scrollTop = 0; // For Safari
    document.documentElement.scrollTop = 0; // For Chrome, Firefox, IE and Opera
  },

  setLoading: (boolean) => {
    App.loading = boolean
    const loader = $('#loader')
    const content = $('#content')
    if (boolean) {
      loader.show()
      content.hide()
    } else {
      loader.hide()
      content.show()
    }
  },

  wrapToHTML: (author, ipfsLink, title, content) => {
    return "<div class=\"jumbotron\">" +
      "<h1 class=\"display-4\">" + title + "</h1>" +
      "<p class=\"lead\">IPFS address: " + ipfsLink + "</p>" +
      "<p class=\"lead\">Author: " + author + "</p>" +
      "<hr class=\"my-4\">" +
      "<div id=\"articleContent\">" +
        content
      "</div>" +
    "</div>"
  }
}

$(() => {
  $(window).load(() => {
    App.init()
    window.onscroll = function() {App.scrollFunction()};
  })
});
