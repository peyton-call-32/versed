import Testing
@testable import Versed

struct LibraryTests {
    @Test func newReadersStartWithEveryBook() {
        #expect(Library.bookIDs(from: Library.starting) == ["course:Old Testament 2026", "ot", "nt", "bofm", "dc", "pgp"])
    }

    @Test func addingABookKeepsTheUsualOrder() {
        #expect(Library.toggling("bofm", in: "ot,pgp") == "ot,bofm,pgp")
        #expect(Library.toggling("course:Old Testament 2026", in: "ot") == "course:Old Testament 2026,ot")
    }

    @Test func aReaderCanRemoveEveryBook() {
        #expect(Library.toggling("ot", in: "ot") == "")
        #expect(Library.bookIDs(from: "").isEmpty)
    }
}
