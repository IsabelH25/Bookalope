#!/bin/bash

if [ $# -ne 2 ]; then
    echo -e "Missing argument(s)\nUsage: $0 token document"
    exit 1
fi

TOKEN=$1
DOCFILE=$2

if [ ! -f "$DOCFILE" ]; then
    echo "Document $DOCFILE does not exist, exiting"
    exit 1
fi

# The Bookalope server.
APIHOST="https://bookflow.bookalope.net"

if [ `builtin type -p http` ]; then

    # Create a new book called "Test"
    BOOKID=`http --json --print=b --auth $TOKEN: POST $APIHOST/api/books name="Test" | python3 -c "import json,sys;obj=json.load(sys.stdin);print(obj['book']['id']);"`
    echo "Created new book $BOOKID"

    # Create a new bookflow "Bookflow 1" for the book "Test"
    BOOKFLOWID=`http --json --print=b --auth $TOKEN: POST $APIHOST/api/books/$BOOKID/bookflows name="Bookflow 1" title="Test" | python3 -c "import json,sys;obj=json.load(sys.stdin);print(obj['bookflow']['id']);"`
    echo "Created new bookflow $BOOKFLOWID"

    # Upload the manuscript which automatically converts it using defaults.
    base64 "$DOCFILE" > "$DOCFILE.base64"
    http --json --auth $TOKEN: POST $APIHOST/api/books/$BOOKID/bookflows/$BOOKFLOWID/files/document file=@"$DOCFILE.base64" filename="$DOCFILE" filetype=doc
    echo "Uploaded document"

    # Download the converted results.
    echo "Downloading converted books"
    http --download --auth $TOKEN: GET $APIHOST/api/books/$BOOKID/bookflows/$BOOKFLOWID/convert format==epub version==test
    http --download --auth $TOKEN: GET $APIHOST/api/books/$BOOKID/bookflows/$BOOKFLOWID/convert format==mobi version==test
    http --download --auth $TOKEN: GET $APIHOST/api/books/$BOOKID/bookflows/$BOOKFLOWID/convert format==pdf version==test
    http --download --auth $TOKEN: GET $APIHOST/api/books/$BOOKID/bookflows/$BOOKFLOWID/convert format==icml version==test
    http --download --auth $TOKEN: GET $APIHOST/api/books/$BOOKID/bookflows/$BOOKFLOWID/convert format==docx version==test

    # Delete the "Test" book and all of its bookflows.
    http --auth $TOKEN: DELETE $APIHOST/api/books/$BOOKID
    echo "Deleted book and bookflows"

else

    if [ `builtin type -p curl` ]; then

        # Create a new book called "Test"
        BOOKID=`curl --user $TOKEN: --header "Content-Type: application/json" --data '{"name":"Test"}' --request POST $APIHOST/api/books | python3 -c "import json,sys;obj=json.load(sys.stdin);print(obj['book']['id']);"`
        echo "Created new book $BOOKID"

        # Create a new bookflow "Bookflow 1" for the book "Test"
        BOOKFLOWID=`curl --user $TOKEN: --header "Content-Type: application/json" --data '{"name":"Bookflow 1", "title":"Test"}' --request POST $APIHOST/api/books/$BOOKID/bookflows | python3 -c "import json,sys;obj=json.load(sys.stdin);print(obj['bookflow']['id']);"`
        echo "Created new bookflow $BOOKFLOWID"

        # Upload the manuscript which automatically converts it using defaults.
        echo '{"filetype":"doc", "filename":"'$DOCFILE'", "file":"' > "$DOCFILE.json"
        base64 "$DOCFILE" >> "$DOCFILE.json"
        echo '"}' >> "$DOCFILE.json"
        curl --user $TOKEN: --header "Content-Type: application/json" --data @"$DOCFILE.json" --request POST $APIHOST/api/books/$BOOKID/bookflows/$BOOKFLOWID/files/document

        # Download the converted results.
        curl --user $TOKEN: --output $BOOKFLOWID.epub --request GET $APIHOST/api/books/$BOOKID/bookflows/$BOOKFLOWID/convert?format=epub\&version=test
        curl --user $TOKEN: --output $BOOKFLOWID.mobi --request GET $APIHOST/api/books/$BOOKID/bookflows/$BOOKFLOWID/convert?format=mobi\&version=test
        curl --user $TOKEN: --output $BOOKFLOWID.pdf --request GET $APIHOST/api/books/$BOOKID/bookflows/$BOOKFLOWID/convert?format=pdf\&version=test
        curl --user $TOKEN: --output $BOOKFLOWID.icml --request GET $APIHOST/api/books/$BOOKID/bookflows/$BOOKFLOWID/convert?format=icml\&version=test
        curl --user $TOKEN: --output $BOOKFLOWID.docx --request GET $APIHOST/api/books/$BOOKID/bookflows/$BOOKFLOWID/convert?format=docx\&version=test

        # Delete the "Test" book and all of its bookflows.
        curl --user $TOKEN: --request DELETE $APIHOST/api/books/$BOOKID
        echo "Deleted book and bookflows"

    else
        echo "Unable to find http or curl command, exiting"
        exit 1
    fi
fi
exit 0