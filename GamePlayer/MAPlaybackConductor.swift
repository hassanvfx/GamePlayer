import Foundation

final class MAPlaybackConductor {
    struct MAState: Equatable {
        let primaryIndex: Int?
        let candidateIndex: Int?
    }

    var onStateChange: ((MAState) -> Void)?

    private let activationDelay: TimeInterval
    private(set) var primaryIndex: Int?
    private(set) var candidateIndex: Int?

    private var activationWorkItem: DispatchWorkItem?

    init(activationDelay: TimeInterval = 3) {
        self.activationDelay = activationDelay
    }

    func updateVisibleCandidate(_ index: Int?) {
        guard candidateIndex != index else {
            return
        }

        candidateIndex = index
        activationWorkItem?.cancel()

        guard let index else {
            notifyStateChange()
            return
        }

        notifyStateChange()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.candidateIndex == index, self.primaryIndex != index else {
                return
            }

            self.primaryIndex = index
            self.notifyStateChange()
        }

        activationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + activationDelay, execute: workItem)
    }

    func reset() {
        activationWorkItem?.cancel()
        activationWorkItem = nil
        primaryIndex = nil
        candidateIndex = nil
        notifyStateChange()
    }

    private func notifyStateChange() {
        onStateChange?(
            MAState(
                primaryIndex: primaryIndex,
                candidateIndex: candidateIndex
            )
        )
    }
}
