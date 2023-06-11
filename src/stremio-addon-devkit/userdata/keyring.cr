module Stremio::Addon::DevKit::UserData
  alias KeyRingSecret = String

  # A KeyRing represents a public/private key mapping.
  # WARNING: The position/index of a specific `String` within the keyring IS important.
  # The purpose of the `KeyRing` is to keep `KeyRingSecret` secret.  This is accomplished
  # by sharing the index number with the outside world, but the actual secret is kept internally.
  #
  # An example would be:
  # ```
  # keyring = {"hotdog": "secret_phrase", "potato": "the secret word"}
  # ```
  # Let's assume we have the phrase "Top Secret" that we want to encrypt and the result is "ADGAD1234==".
  # We give this encrypted content to a random user.  This random user doesn't actually know what the
  # phrase is - but when they return it, we want to decrypt "ADGAD1234==" and get our original phrase
  # "Top Secret".  However, we don't know if "secret_phrase" or "the secret word" was used to decrypt
  # "ADGAD1234==".  We could try them all, but that would take time.
  #
  # A niative solution would be to prepent the actual secret used with the encrypted content.  So
  # we'd send our random user the phrase "the secret word:ADGAD1234==", but this means the user
  # could easily decrypt the content, modify it, and send it to our application.  INSTEAD we'll use
  # the "public" phrase and give our random user "potato:ADGAD1234==".  The word "potato" is completely
  # meaningless to our random user (as is the encrypted content), but when the user gives our application
  # the phrase "potato:ADGAD1234==" - the word "potato" has a meaning for US and we know that we'll need
  # to use "the secret word" to decrypt "ADGAD1234==", which will reveal our secret "Top Secret".
  #
  # `KeyRing` behaves in the same way, except instead of long words like "hotdog" and "potato", we use
  # index number.  Basically
  # ```
  # keyring = [nil, "secret_phrase", nil, nil, "the secret word", nil]
  # ```
  # and we send our random user "4:ADGAD1234==".  Notice that "the secret word" is at the index 4 in our Array.
  # This is also why it's critical that we never change the order of this index, but you're welcome to replace
  # the nil with new secrets.
  #
  class KeyRing < Array(KeyRingSecret?)
    # This is an internal flag, which means we do NOT want to use the `KeyRing`
    enum Opt
      Disable = 7
    end

    # Constructs a fixed length `Array`
    def initialize
      super(Opt::Disable.value - 1, nil)
    end

    # Constructs a fixed length `Array`, raises an exception if unable to parse `csv`
    # * `csv` : A comma seperated tuple of "position:secret".
    #
    # Example
    # ```
    # x = KeyRing.new("5:world,3:hello")
    # puts x # [ nil, nil, nil, "hello", nil, "world", nil ]
    # ```
    def initialize(csv : String)
      super(Opt::Disable.value - 1, nil)
    end
  end
end
