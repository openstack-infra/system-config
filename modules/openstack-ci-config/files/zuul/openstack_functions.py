def devstack_params(change, params):
    if change.branch == 'stable/diablo':
        params['NODE'] = 'devstack-oneiric'
