var UUIDProvider = artifacts.require("UUIDProvider.sol");

contract('UUIDProvider', function(accounts) {
  let provider;
  const countID = 300;
  let IDs;

  before(async function(){
    provider = await UUIDProvider.new();
    IDs = [];
  })

  it("should create " + countID + " UUIDs", async function() {
    for (var i = 0; i < countID; i++) {
      let { logs } = await provider.UUID4()
      let event = logs.find(e => e.event === "UUID")
      assert.equal(IDs.indexOf(event.args.uuid), -1)
      IDs.push(event.args.uuid)

      process.stdout.clearLine()
      process.stdout.cursorTo(4)
      process.stdout.write("UUIDs tested: " + (i+1))
    }
    console.log('')
  });
});
