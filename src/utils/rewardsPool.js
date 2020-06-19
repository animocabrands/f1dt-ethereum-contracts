const { BN } = require('@openzeppelin/test-helpers');

function rewardsPoolFromSchedule(schedule, periodLengthInCycles) {
    return schedule.reduce(
        ((total, schedule) => {
            return total.add(
                new BN(schedule.payoutPerCycle)
                .mul(new BN(periodLengthInCycles))
                .mul(new BN(schedule.endPeriod - schedule.startPeriod + 1))
            )
        }),
        new BN(0)
    );
}

module.exports = {
    rewardsPoolFromSchedule
}