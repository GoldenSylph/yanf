App = {
  web3Provider: null,
  contracts: {},
  account: '0x0',
  loading: false,

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

  sendFees: async () => {
    const feeReceiver = $('#feeReceiverInput').val();
    const feeAmount = $('#feeAmountInput').val();

    if (feeReceiver == null || feeReceiver === ''
        || feeAmount == null || feeAmount === '' || feeAmount <= 0) {
      return;
    }

    await App.contracts.YANFManagerSimplified.deployed()
      .then((instance) => {
        return instance.sendFees(feeReceiver, web3.toWei(feeAmount, 'ether'), {from: App.account});
      })
      .then((result) => {
        window.alert('Revenue sent.');
      })
      .catch((error) => {
        console.log('An error occurred during the connection: ' + error);
        window.alert('Sorry, can not send revenue. Please reload the page.');
      });
  },

  render: async () => {
    if (App.loading) {
      return;
    }
    App.setLoading(true);
    App.account = web3.eth.accounts[0];
    $('#viewing_author').html(App.account);
    await App.searchBy(App.account);
    await web3.eth.getBalance(App.contracts.YANFManagerSimplified.address, (err, balance) => {
      $('#currentBalance').html('Current balance of the contract is: '
        + web3.fromWei(balance, 'ether') + ' ETH');
    });

    await App.contracts.YANFManagerSimplified.deployed()
      .then((instance) => {
        return instance.isOwner.call({from: App.account});
      })
      .then((result) => {
        if (result) {
          $('#admin').html(
            "<button type=\"button\" class=\"btn btn-danger form-control\"" +
            "data-toggle=\"modal\" data-target=\"#adminModal\">" +
            "Admin" +
          "</button>");
        }
      })
      .catch((error) => {
        console.log('An error occurred during the connection: ' + error);
        window.alert('Sorry, the connection is failed. Please reload the page.');
      });

    App.setLoading(false);
  },

  publish: async () => {

    const title = $('#title').val();
    const price = $('#price').val();
    const articleContent = simplemde.value();

    if (title === '' || title == null
      || articleContent == null || articleContent === ''
      || price == null || price === '') {
      return;
    }

    console.log('Published with price ' + price);

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
        return instance.publish(title, articleHash, web3.toWei(price, 'ether'),
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

    if (authorAddr == null || authorAddr === '') {
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
      $('#article_container').html('<h2>Sorry, this author hasn\'t got any articles.</h2>');
    } else {
      for (i = 0; i < articlesCount; i++) {

        var articleTitle;
        var articleIPFSLink;
        var articleContent;
        var articlePrice;

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

        await App.contracts.YANFManagerSimplified.deployed()
          .then((instance) => {
            return instance.getArticlePriceByIndex.call(authorAddress, i, {from: App.account});
          })
          .then((result) => {
            articlePrice = result;
          })
          .catch((error) => {
            console.log('An error occurred during the price searching: ' + error);
            window.alert('Sorry, we can not proceed this search request. You can contact to us, so we could help you.');
          });

        if (articleIPFSLink !== 'FORBIDDEN') {
          await App.ipfs.cat(articleIPFSLink)
            .then((value) => {
              articleContent = value.toString();
            })
            .catch((error) => {
              console.log('IPFS cat error: ' + error);
              window.alert('Sorry, we can not connect to the IPFS.');
            });
        }

        articleContent = App.converter.makeHtml(articleContent);
        var newArticle = App.wrapToHTMLWithIdentificationDiv(authorAddress,
          articleIPFSLink, articleTitle, articleContent, articlePrice, i);
        $('#article_container').prepend(newArticle);
      }
    }
    $('#viewing_author').html(authorAddress);
    App.setLoading(false);
  },

  buy: async (author, articleIndex, price) => {

    if (author == null || author === ''
      || articleIndex == null || articleIndex === ''
      || price == null || price === '') {
      return;
    }

    var bought = false;

    const instanceTemp = await App.contracts.YANFManagerSimplified.deployed();
    const boughtEvent = instanceTemp.Bought({});
    boughtEvent.watch(async (err, result) => {
      console.log("Bought event emit: feedOwner: " + result.args.feedOwner + ", " +
          "articleIndex: " + result.args.articleIndex + ", sender: " + result.args.sender +
          ", result: " + result.args.result + ", price: " + result.args.price + ", " +
          "givenAmount: " + result.args.givenAmount);
      boughtEvent.stopWatching();
    });

    await App.contracts.YANFManagerSimplified.deployed().then((instance) => {
      return instance.buy(author, articleIndex, {from: App.account, value: price});
    })
    .then((result) => {
      App.buying_result = result;
      window.alert("Buying, standby...");
      bought = true;
    })
    .catch((error) => {
      console.log('An error occurred during buying: ' + error);
      window.alert('Sorry, you did not buy this article. You can contact to us, so we could help you.');
    });

    if (bought) {

      var articleTitle;
      var articleContent;
      var ipfsLink;

      await App.contracts.YANFManagerSimplified.deployed()
        .then((instance) => {
          return instance.getArticleTitleByIndex.call(author, articleIndex, {from: App.account});
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
          return instance.getArticleContentHashByIndex.call(author, articleIndex, {from: App.account});
        })
        .then((result) => {
          ipfsLink = result;
        })
        .catch((error) => {
          console.log('An error occurred during the content hash searching: ' + error);
          window.alert('Sorry, we can not proceed this search request. You can contact to us, so we could help you.');
        });

      await App.ipfs.cat(ipfsLink)
        .then((value) => {
          articleContent = value.toString();
        })
        .catch((error) => {
          console.log('IPFS cat error: ' + error);
          window.alert('Sorry, we can not connect to the IPFS.');
        });

      const elem = author + '-' + articleIndex;
      $('#' + elem).html(App.wrapToHTML(author, ipfsLink, articleTitle, articleContent, price, articleIndex));
    }

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

  wrapToHTMLWithIdentificationDiv: (author, ipfsLink, title, content, price, articleIndex) => {
    return "<div id=\"" + author + "-" + articleIndex + "\">" +
      App.wrapToHTML(author, ipfsLink, title, content, price, articleIndex) +
      "</div>"
  },

  wrapToHTML: (author, ipfsLink, title, content, price, articleIndex) => {
    return "<div class=\"jumbotron\">" +
      "<p class=\"lead font-weight-bold text-justify\">" + title + "</p>" +
      "<p class=\"lead text-justify\">Price: " + web3.fromWei(price, 'ether') + " ETH</p>" +
      "<hr class=\"my-4\">" +
      "<div id=\"articleContent\">" +
        (ipfsLink === 'FORBIDDEN' ?
          "<form id=\"buyForm\" onSubmit=\"App.buy('" + author + "', " + articleIndex + ", " + price + "); return false;\" class=\"form-inline my-2 my-lg-0\" role=\"form\">" +
            "<button class=\"btn btn-success my-2 my-sm-0\" type=\"submit\">Buy</button>" +
          "</form>"
          : content) +
      "</div>" +
      "<hr class=\"my-4\">" +
      "<small>Page: " + (articleIndex + 1) + "</small>" +
    "</div>";
  }
}

$(() => {
  $(window).load(() => {
    App.init()
    window.onscroll = function() {App.scrollFunction()};
  })
});
